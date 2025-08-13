import unittest
import json
import uuid as uuid_module
from app import app


class UtilsZooTestCase(unittest.TestCase):
    def setUp(self):
        self.app = app
        self.client = self.app.test_client()
        self.app.config["TESTING"] = True

    def test_home_page(self):
        """Test that home page loads successfully"""
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Zoo Utilities", response.data)
        self.assertIn(b"UUID Generator", response.data)
        self.assertIn(b"Who Am I", response.data)

    def test_uuid_page(self):
        """Test UUID generation page"""
        response = self.client.get("/uuid")
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"UUID Generator", response.data)
        # Check that a valid UUID is present in the response
        response_text = response.data.decode("utf-8")
        # Extract UUID from the response
        import re

        uuid_pattern = re.compile(
            r"[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}",
            re.IGNORECASE,
        )
        matches = uuid_pattern.findall(response_text)
        self.assertTrue(len(matches) > 0, "No UUID found in response")
        # Validate the UUID
        try:
            uuid_module.UUID(matches[0])
        except ValueError:
            self.fail(f"Invalid UUID format: {matches[0]}")

    def test_whoami_page(self):
        """Test Who Am I page"""
        response = self.client.get("/whoami", headers={"User-Agent": "TestBot/1.0"})
        self.assertEqual(response.status_code, 200)
        self.assertIn(b"Who Am I", response.data)
        self.assertIn(b"Your IP Address", response.data)
        self.assertIn(b"User Agent", response.data)
        self.assertIn(b"TestBot/1.0", response.data)

    def test_api_uuid(self):
        """Test API UUID endpoint"""
        response = self.client.get("/api/uuid")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content_type, "application/json")

        data = json.loads(response.data)
        self.assertIn("uuid", data)

        # Validate UUID format
        try:
            uuid_module.UUID(data["uuid"])
        except ValueError:
            self.fail(f"Invalid UUID format: {data['uuid']}")

    def test_api_whoami(self):
        """Test API Who Am I endpoint"""
        response = self.client.get(
            "/api/whoami",
            headers={"User-Agent": "TestBot/1.0", "Accept-Language": "en-US,en;q=0.9"},
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content_type, "application/json")

        data = json.loads(response.data)
        self.assertIn("ip", data)
        self.assertIn("user_agent", data)
        self.assertIn("method", data)
        self.assertIn("host", data)
        self.assertIn("headers", data)

        self.assertEqual(data["user_agent"], "TestBot/1.0")
        self.assertEqual(data["method"], "GET")

    def test_health_endpoint(self):
        """Test health check endpoint"""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.content_type, "application/json")

        data = json.loads(response.data)
        self.assertEqual(data["status"], "healthy")
        self.assertEqual(data["service"], "utils-zoo")

    def test_uuid_uniqueness(self):
        """Test that UUID endpoint generates unique values"""
        uuids = set()
        for _ in range(10):
            response = self.client.get("/api/uuid")
            data = json.loads(response.data)
            uuids.add(data["uuid"])

        # All UUIDs should be unique
        self.assertEqual(len(uuids), 10)

    def test_whoami_headers_forwarding(self):
        """Test that various headers are properly captured"""
        custom_headers = {
            "User-Agent": "CustomBot/2.0",
            "Accept-Language": "fr-FR,fr;q=0.9",
            "Accept-Encoding": "gzip, deflate",
            "X-Custom-Header": "test-value",
        }

        response = self.client.get("/api/whoami", headers=custom_headers)
        data = json.loads(response.data)

        self.assertEqual(data["user_agent"], "CustomBot/2.0")
        self.assertIn("Accept-Language", data["headers"])
        self.assertIn("Accept-Encoding", data["headers"])
        self.assertIn("X-Custom-Header", data["headers"])


if __name__ == "__main__":
    unittest.main()
