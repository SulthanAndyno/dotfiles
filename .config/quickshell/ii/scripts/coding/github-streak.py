#!/usr/bin/env python3
"""Fetch GitHub contribution calendar and compute streak statistics."""

from __future__ import annotations

import datetime
import html
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

LEVEL_MAP = {
    "NONE": 0,
    "FIRST_QUARTILE": 1,
    "SECOND_QUARTILE": 2,
    "THIRD_QUARTILE": 3,
    "FOURTH_QUARTILE": 4,
}

GRAPHQL_QUERY = """
query($login: String!) {
  user(login: $login) {
    login
    contributionsCollection {
      contributionCalendar {
        totalContributions
        weeks {
          contributionDays {
            date
            contributionCount
            contributionLevel
          }
        }
      }
    }
  }
}
""".strip()


def resolve_default_username() -> str:
    try:
        res = subprocess.run(
            ["git", "config", "--global", "user.name"],
            capture_output=True,
            text=True,
            timeout=2,
            check=False,
        )
        name = res.stdout.strip()
        if name:
            return name
    except Exception:
        pass
    return "SulthanAndyno"


def fetch_via_gh(username: str) -> tuple[str, int, list[list[dict]]] | None:
    try:
        res = subprocess.run(
            [
                "gh",
                "api",
                "graphql",
                "-f",
                f"query={GRAPHQL_QUERY}",
                "-F",
                f"login={username}",
            ],
            capture_output=True,
            text=True,
            timeout=12,
            check=False,
        )
        if res.returncode != 0 or not res.stdout.strip():
            return None
        payload = json.loads(res.stdout)
        user_data = (payload.get("data") or {}).get("user")
        if not user_data:
            return None
        cal = user_data["contributionsCollection"]["contributionCalendar"]
        weeks: list[list[dict]] = []
        for week in cal.get("weeks", []):
            days = []
            for day in week.get("contributionDays", []):
                days.append(
                    {
                        "date": day["date"],
                        "count": int(day.get("contributionCount", 0)),
                        "level": LEVEL_MAP.get(day.get("contributionLevel", "NONE"), 0),
                    }
                )
            if days:
                weeks.append(days)
        return user_data.get("login", username), int(cal.get("totalContributions", 0)), weeks
    except Exception:
        return None


def fetch_via_public_html(username: str) -> tuple[str, int, list[list[dict]]] | None:
    url = f"https://github.com/users/{username}/contributions"
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "quickshell-github-streak/1.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            body = resp.read().decode("utf-8", errors="replace")
    except (urllib.error.URLError, TimeoutError, OSError):
        return None

    # Parse day cells: id="contribution-day-component-..." data-date="YYYY-MM-DD" ... data-level="N"
    day_matches = re.findall(
        r'id="(contribution-day-component-[^"]+)"[^>]*data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="(\d)"',
        body,
    )
    if not day_matches:
        day_matches = [
            ("", d, lvl)
            for d, lvl in re.findall(
                r'data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="(\d)"', body
            )
        ]
    if not day_matches:
        return None

    # Parse tooltip counts keyed by component id
    tooltip_counts: dict[str, int] = {}
    for for_id, text in re.findall(r'<tool-tip[^>]*for="([^"]+)"[^>]*>([^<]+)</tool-tip>', body):
        clean_text = html.unescape(text).strip()
        m = re.match(r"(\d+)\s+contribution", clean_text)
        tooltip_counts[for_id] = int(m.group(1)) if m else 0

    all_days = []
    for comp_id, day_str, level_str in day_matches:
        level = max(0, min(4, int(level_str)))
        count = tooltip_counts.get(comp_id, level if level > 0 else 0)
        all_days.append({"date": day_str, "count": count, "level": level})

    all_days.sort(key=lambda d: d["date"])

    total = 0
    total_match = re.search(r"([\d,]+)\s+contributions?\s+in\s+the\s+last\s+year", body)
    if total_match:
        total = int(total_match.group(1).replace(",", ""))
    else:
        total = sum(d["count"] for d in all_days)

    # Group into Sunday-start weeks
    weeks: list[list[dict]] = []
    current_week: list[dict] = []
    for day in all_days:
        dt = datetime.date.fromisoformat(day["date"])
        # GitHub weeks run Sunday (weekday=6 in Python) -> Saturday (weekday=5)
        if dt.weekday() == 6 and current_week:
            weeks.append(current_week)
            current_week = []
        current_week.append(day)
    if current_week:
        weeks.append(current_week)

    return username, total, weeks


def compute_stats(weeks: list[list[dict]], weeks_shown: int) -> dict:
    today = datetime.date.today()
    today_iso = today.isoformat()

    day_map: dict[datetime.date, int] = {}
    for week in weeks:
        for day in week:
            dt = datetime.date.fromisoformat(day["date"])
            if dt <= today:
                day_map[dt] = int(day.get("count", 0))

    today_count = day_map.get(today, 0)

    # Longest streak across fetched calendar
    longest_streak = 0
    running = 0
    for dt in sorted(day_map.keys()):
        if day_map[dt] > 0:
            running += 1
            if running > longest_streak:
                longest_streak = running
        else:
            running = 0

    # Current streak: if today has commits start from today, else start from yesterday
    cursor = today if today_count > 0 else (today - datetime.timedelta(days=1))
    current_streak = 0
    while day_map.get(cursor, 0) > 0:
        current_streak += 1
        cursor -= datetime.timedelta(days=1)

    sliced_weeks = weeks[-weeks_shown:] if len(weeks) > weeks_shown else weeks

    month_labels: list[str] = []
    prev_month = ""
    for idx, week in enumerate(sliced_weeks):
        if not week:
            month_labels.append("")
            continue
        dt = datetime.date.fromisoformat(week[0]["date"])
        month_name = dt.strftime("%b")
        if month_name != prev_month and (idx > 0 or dt.day <= 7):
            month_labels.append(month_name)
            prev_month = month_name
        else:
            if not prev_month:
                prev_month = month_name
            month_labels.append("")

    return {
        "todayDate": today_iso,
        "todayCount": today_count,
        "todayDone": today_count > 0,
        "currentStreak": current_streak,
        "longestStreak": longest_streak,
        "weeks": sliced_weeks,
        "monthLabels": month_labels,
    }


def main() -> int:
    username = sys.argv[1].strip() if len(sys.argv) > 1 and sys.argv[1].strip() else resolve_default_username()
    try:
        weeks_shown = max(4, min(52, int(sys.argv[2]))) if len(sys.argv) > 2 else 20
    except ValueError:
        weeks_shown = 20

    cache_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "quickshell"
    cache_dir.mkdir(parents=True, exist_ok=True)
    safe_user = re.sub(r"[^A-Za-z0-9._-]", "_", username)
    cache_file = cache_dir / f"github-streak-{safe_user}.json"

    fetched = fetch_via_gh(username) or fetch_via_public_html(username)
    now_str = datetime.datetime.now().strftime("%H:%M")

    if fetched is not None:
        resolved_user, total_year, all_weeks = fetched
        raw_payload = {
            "username": resolved_user,
            "totalYear": total_year,
            "allWeeks": all_weeks,
            "updatedAt": now_str,
        }
        try:
            cache_file.write_text(json.dumps(raw_payload), encoding="utf-8")
        except OSError:
            pass
        stats = compute_stats(all_weeks, weeks_shown)
        output = {
            "username": resolved_user,
            "totalYear": total_year,
            "updatedAt": now_str,
            "cached": False,
            **stats,
        }
        print(json.dumps(output))
        return 0

    if cache_file.exists():
        try:
            cached = json.loads(cache_file.read_text(encoding="utf-8"))
            all_weeks = cached.get("allWeeks", [])
            stats = compute_stats(all_weeks, weeks_shown)
            output = {
                "username": cached.get("username", username),
                "totalYear": int(cached.get("totalYear", 0)),
                "updatedAt": cached.get("updatedAt", "--:--"),
                "cached": True,
                **stats,
            }
            print(json.dumps(output))
            return 0
        except Exception:
            pass

    print(json.dumps({"username": username, "error": "Unable to fetch GitHub contributions", "weeks": []}))
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
