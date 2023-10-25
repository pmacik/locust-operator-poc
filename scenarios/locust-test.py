from locust import User, task, events
from locust.exception import LocustError
import time
import random


class UserScenario(User):
    @task
    def tick(self) -> None:
        w = random.random()
        print(f"Sleeping for {w}s")
        time.sleep(w)
        if w > 1.75:
            self._report_failure("tick", "fast-tick", w*1000.0, "too late!")
        else:
            self._report_success("tick", "fast-tick", w*1000.0)

    def _report_success(self, category, name, response_time):
        events.request.fire(
            request_type=category,
            name=name,
            response_time=response_time,
            response_length=0,
            exception=None
        )

    def _report_failure(self, category, name, response_time, msg):
        events.request.fire(
            request_type=category,
            name=name,
            response_time=response_time,
            response_length=0,
            exception=LocustError(msg)
        )
