from locust import HttpUser, task, between
import random
import string
import json

def random_order():
    return {
        "product": random.choice(["burger", "pizza", "salad"]),
        "quantity": random.randint(1, 5),
        "customer": ''.join(random.choices(string.ascii_letters, k=6))
    }

class OrderUser(HttpUser):
    wait_time = between(1, 3)

    @task
    def create_order(self):
        headers = {"Content-Type": "application/json"}
        payload = random_order()
        self.client.post("/order", data=json.dumps(payload), headers=headers)
