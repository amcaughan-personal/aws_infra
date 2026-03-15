import datetime
import json
import pathlib
import types
import unittest
from unittest import mock


TEMPLATE_PATH = (
    pathlib.Path(__file__).resolve().parents[1]
    / "infra/terragrunt/modules/cleanup-janitor/lambda.py.tftpl"
)


class _FakeClient:
    def __getattr__(self, name):
        raise AssertionError(f"unexpected client call: {name}")


class _FakeBoto3(types.ModuleType):
    def client(self, name):
        del name
        return _FakeClient()


class _FakeClientError(Exception):
    pass


def _load_lambda_module():
    source = TEMPLATE_PATH.read_text()
    replacements = {
        "accepted_cleanup_tag_names": json.dumps(["auto_cleanup", "auto-cleanup"]),
        "accepted_cleanup_ttl_tag_names": json.dumps(["cleanup_ttl", "cleanup-ttl", "ttl"]),
        "cleanup_schedule_tag_name": "cleanup_schedule",
        "cleanup_ttl_tag_name": "cleanup_ttl",
        "cleanup_tag_name": "auto_cleanup",
        "created_at_tag_name": "created_at",
        "created_on_tag_name": "created_on",
        "monthly_cleanup_day": "1",
        "weekly_cleanup_weekday": "fri",
    }
    for key, value in replacements.items():
        source = source.replace(f"${{{key}}}", value)

    fake_boto3 = _FakeBoto3("boto3")
    fake_botocore = types.ModuleType("botocore")
    fake_exceptions = types.ModuleType("botocore.exceptions")
    fake_exceptions.ClientError = _FakeClientError

    module = types.ModuleType("cleanup_janitor_lambda")
    with mock.patch.dict(
        "sys.modules",
        {
            "boto3": fake_boto3,
            "botocore": fake_botocore,
            "botocore.exceptions": fake_exceptions,
        },
    ):
        exec(source, module.__dict__)
    return module


class CleanupJanitorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.module = _load_lambda_module()

    def test_resource_type_and_id_cover_new_resource_types(self):
        cases = {
            "arn:aws:athena:us-east-2:123456789012:workgroup/demo": ("athena:workgroup", "demo"),
            "arn:aws:ecr:us-east-2:123456789012:repository/demo": ("ecr:repository", "demo"),
            "arn:aws:logs:us-east-2:123456789012:log-group:/aws/demo:*": ("logs:log-group", "/aws/demo"),
            "arn:aws:s3:::demo-bucket": ("s3:bucket", "demo-bucket"),
            "arn:aws:scheduler:us-east-2:123456789012:schedule/default/demo": ("scheduler:schedule", "default/demo"),
        }

        for arn, (resource_type, resource_id) in cases.items():
            with self.subTest(arn=arn):
                self.assertEqual(self.module._resource_type(arn), resource_type)
                self.assertEqual(self.module._resource_id(arn), resource_id)

    def test_parse_ttl_supports_multiple_units(self):
        self.assertEqual(self.module._parse_ttl("15m"), datetime.timedelta(minutes=15))
        self.assertEqual(self.module._parse_ttl("12"), datetime.timedelta(hours=12))
        self.assertEqual(self.module._parse_ttl("3d"), datetime.timedelta(days=3))
        self.assertEqual(self.module._parse_ttl("2w"), datetime.timedelta(weeks=2))

    def test_ttl_cleanup_takes_precedence_over_legacy_schedule(self):
        now = datetime.datetime(2026, 3, 15, 12, 0, tzinfo=datetime.UTC)
        should_cleanup, reason = self.module._should_cleanup(
            {
                "auto_cleanup": "true",
                "cleanup_schedule": "monthly",
                "cleanup_ttl": "1d",
                "created_on": "2026-03-13",
            },
            now,
        )

        self.assertTrue(should_cleanup)
        self.assertEqual(reason, "ttl_due")

    def test_ttl_cleanup_waits_when_not_due(self):
        now = datetime.datetime(2026, 3, 15, 12, 0, tzinfo=datetime.UTC)
        should_cleanup, reason = self.module._should_cleanup(
            {
                "auto_cleanup": "true",
                "cleanup_ttl": "7d",
                "created_at": "2026-03-12T08:00:00Z",
            },
            now,
        )

        self.assertFalse(should_cleanup)
        self.assertEqual(reason, "ttl_not_due_yet")

    def test_weekly_cleanup_without_created_on_uses_existing_schedule_logic(self):
        friday = datetime.datetime(2026, 3, 20, 9, 0, tzinfo=datetime.UTC)
        should_cleanup, reason = self.module._should_cleanup(
            {
                "auto_cleanup": "true",
                "cleanup_schedule": "weekly",
            },
            friday,
        )

        self.assertTrue(should_cleanup)
        self.assertEqual(reason, "weekly_due")


if __name__ == "__main__":
    unittest.main()
