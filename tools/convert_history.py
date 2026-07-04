import json
import re
from pathlib import Path


SOURCE = Path("历史训练记录.md")
OUTPUT = Path("assets/data/history_workout_records.json")

EXERCISES = {
    "反手高位下拉": ("背", "weighted", "kg", False),
    "高位下拉": ("背", "weighted", "kg", False),
    "坐姿水平划船": ("背", "weighted", "kg", False),
    "杠铃划船": ("背", "weighted", "kg", False),
    "俯身哑铃划船": ("背", "weighted", "kg", True),
    "单边哑铃划船": ("背", "weighted", "kg", True),
    "跪姿单边划船": ("背", "weighted", "kg", True),
    "仰卧直臂上拉": ("背", "weighted", "kg", False),
    "绳索面拉": ("背", "weighted", "kg", False),
    "引体向上": ("背", "bodyweight", "reps", False),
    "对握引体": ("背", "bodyweight", "reps", False),
    "辅助对握引体": ("背", "bodyweight", "reps", False),
    "辅助引体": ("背", "bodyweight", "reps", False),
    "澳式引体": ("背", "bodyweight", "reps", False),
    "引体": ("背", "bodyweight", "reps", False),
    "反手引体": ("背", "bodyweight", "reps", False),
    "史密斯深蹲": ("腿", "weighted", "kg", False),
    "自由深蹲": ("腿", "weighted", "kg", False),
    "深蹲热身": ("腿", "weighted", "kg", False),
    "深蹲": ("腿", "weighted", "kg", False),
    "泽奇": ("腿", "weighted", "kg", False),
    "硬拉": ("腿", "weighted", "kg", False),
    "哑铃单腿硬拉": ("腿", "weighted", "kg", True),
    "单腿硬拉": ("腿", "weighted", "kg", True),
    "保加利亚蹲": ("腿", "weighted", "kg", True),
    "单腿蹲": ("腿", "bodyweight", "reps", True),
    "中腿跳": ("腿", "weighted", "kg", False),
    "固定器械内收": ("腿", "weighted", "kg", False),
    "内收肌": ("腿", "weighted", "kg", False),
    "提踵": ("腿", "weighted", "kg", False),
    "西班牙蹲": ("腿", "bodyweight", "reps", False),
    "平板哑铃卧推": ("胸", "weighted", "kg", False),
    "哑铃交替卧推": ("胸", "weighted", "kg", False),
    "卧推": ("胸", "weighted", "kg", False),
    "俯卧撑": ("胸", "bodyweight", "reps", False),
    "固定夹胸": ("胸", "weighted", "kg", False),
    "飞鸟": ("胸", "weighted", "kg", False),
    "实力推": ("肩", "weighted", "kg", False),
    "坐姿哑铃推肩": ("肩", "weighted", "kg", False),
    "哑铃推肩": ("肩", "weighted", "kg", False),
    "龙门架外旋侧拉": ("肩", "weighted", "kg", True),
    "TYW": ("肩", "mobility", "done", False),
    "空手死虫": ("核心", "bodyweight", "reps", False),
    "死虫": ("核心", "weighted", "kg", False),
    "哥本哈根支撑": ("核心", "timed", "sec", True),
    "侧支撑": ("核心", "timed", "sec", True),
    "跪姿屈髋平板支撑": ("核心", "timed", "sec", True),
    "坐姿髋屈": ("核心", "bodyweight", "reps", True),
    "水平伐木": ("核心", "weighted", "kg", True),
    "龙门架水平推抗旋": ("核心", "weighted", "kg", True),
    "龙门架水平推": ("核心", "weighted", "kg", True),
    "龙门架水平拉": ("核心", "weighted", "kg", True),
    "绳索单侧前推": ("核心", "weighted", "kg", True),
    "龙门架核心抗旋": ("核心", "weighted", "kg", True),
    "弹力带拥抱": ("胸", "bodyweight", "reps", False),
    "单腿臀桥": ("臀", "bodyweight", "reps", True),
    "山羊挺身": ("臀", "weighted", "kg", False),
    "跑步机": ("有氧", "cardio", "min", False),
    "间歇跑": ("有氧", "cardio", "min", False),
    "羽毛球": ("有氧", "cardio", "min", False),
    "爬坡": ("有氧", "cardio", "min", False),
    "胸椎灵活性": ("灵活性", "mobility", "done", False),
    "髋屈肌拉伸": ("灵活性", "mobility", "done", True),
    "鸟狗式": ("灵活性", "mobility", "reps", True),
    "臀肌拉伸": ("灵活性", "mobility", "done", True),
}

EXERCISE_NAMES = sorted(EXERCISES, key=len, reverse=True)


def normalize(line: str) -> str:
    line = re.sub(r"^- \[ \]\s*", "", line.strip())
    replacements = {
        "，": " ",
        "、": " ",
        "（": "(",
        "）": ")",
        "－": "-",
        "—": "-",
        "×": "x",
    }
    for old, new in replacements.items():
        line = line.replace(old, new)
    return re.sub(r"\s+", " ", line).strip()


def find_exercise_name(line: str) -> str | None:
    for name in EXERCISE_NAMES:
        if name in line:
            return name
    return None


def title_from(header: str) -> str:
    if "恢复训练" in header:
        return "恢复训练"
    if "功能性训练" in header:
        return "功能性训练"
    if "训练计划" in header:
        return "训练计划"
    return "训练"


def date_from(header: str) -> str:
    match = re.match(r"26\.(\d{1,2})\.(\d{1,2})", header)
    if not match:
        raise ValueError(f"Invalid header: {header}")
    return f"2026-{int(match.group(1)):02d}-{int(match.group(2)):02d}"


def numbers(text: str) -> list[float]:
    return [float(item) for item in re.findall(r"\d+(?:\.\d+)?", text)]


def set_record(
    index: int,
    *,
    weight: float | None = None,
    reps: float | None = None,
    time_sec: int | None = None,
    speed: float | None = None,
    side: str = "none",
    completed: bool = True,
) -> dict:
    return {
        "setIndex": index,
        "weight": weight,
        "reps": reps,
        "timeSec": time_sec,
        "distanceKm": None,
        "speed": speed,
        "side": side,
        "completed": completed,
        "rpe": None,
        "createdAt": None,
        "completedAt": None,
        "updatedAt": None,
    }


def parse_sets(line: str, exercise_type: str, completed: bool) -> list[dict]:
    line = normalize(line)
    side = "both" if any(token in line for token in ["每边", "两边", "左右", "each"]) else "none"

    if exercise_type == "mobility":
        return [set_record(1, completed=completed)]

    if exercise_type == "cardio":
        speed_match = re.search(r"(\d+(?:\.\d+)?)\s*km/h", line, re.I)
        speed = float(speed_match.group(1)) if speed_match else None
        minutes = sum(
            float(match.group(1))
            for match in re.finditer(r"(\d+(?:\.\d+)?)\s*min", line, re.I)
        )
        if minutes == 0:
            match = re.search(r"(\d+(?:\.\d+)?)\s*分钟", line)
            if match:
                minutes = float(match.group(1))
        if minutes == 0:
            values = numbers(line)
            minutes = values[0] if values else 0
        return [
            set_record(
                1,
                time_sec=round(minutes * 60),
                speed=speed,
                completed=completed,
            )
        ]

    if exercise_type == "timed":
        match = re.search(r"(\d+(?:\.\d+)?)\s*s\s*x\s*(\d+)", line, re.I)
        if match:
            sec = round(float(match.group(1)))
            count = int(float(match.group(2)))
            return [
                set_record(i + 1, time_sec=sec, side=side, completed=completed)
                for i in range(count)
            ]
        match = re.search(r"(\d+(?:\.\d+)?)\s*s", line, re.I)
        count_match = re.search(r"(\d+)\s*组", line)
        count = int(count_match.group(1)) if count_match else 1
        if match:
            sec = round(float(match.group(1)))
            return [
                set_record(i + 1, time_sec=sec, side=side, completed=completed)
                for i in range(count)
            ]
        return [set_record(1, side=side, completed=completed)]

    kg_x_matches = re.findall(
        r"(\d+(?:\.\d+)?)\s*kg\s*-?\s*(\d+(?:\.\d+)?)\s*x\s*(\d+)",
        line,
        re.I,
    )
    parsed_sets: list[dict] = []
    for weight, reps, count in kg_x_matches:
        for _ in range(int(count)):
            parsed_sets.append(
                set_record(
                    len(parsed_sets) + 1,
                    weight=float(weight),
                    reps=float(reps),
                    side=side,
                    completed=completed,
                )
            )
    if parsed_sets:
        return parsed_sets

    kg_values = [
        float(value) for value in re.findall(r"(\d+(?:\.\d+)?)\s*kg", line, re.I)
    ]
    x_matches = re.findall(
        r"(?:(\d+(?:\.\d+)?)\s*kg\s*)?(\d+(?:\.\d+)?)\s*x\s*(\d+)",
        line,
        re.I,
    )
    if x_matches:
        for weight, reps, count in x_matches:
            parsed_weight = float(weight) if weight else (kg_values[0] if kg_values else None)
            for _ in range(int(count)):
                parsed_sets.append(
                    set_record(
                        len(parsed_sets) + 1,
                        weight=parsed_weight,
                        reps=float(reps),
                        side=side,
                        completed=completed,
                    )
                )
        return parsed_sets

    if exercise_type == "weighted":
        if kg_values:
            after_last_kg = line.split("kg")[-1]
            rep_values = numbers(after_last_kg)
            if len(kg_values) == 1 and rep_values:
                return [
                    set_record(
                        i + 1,
                        weight=kg_values[0],
                        reps=reps,
                        side=side,
                        completed=completed,
                    )
                    for i, reps in enumerate(rep_values)
                ]
            if len(kg_values) > 1 and rep_values:
                reps = rep_values[-1]
                return [
                    set_record(
                        i + 1,
                        weight=weight,
                        reps=reps,
                        side=side,
                        completed=completed,
                    )
                    for i, weight in enumerate(kg_values)
                ]
            return [
                set_record(i + 1, weight=weight, side=side, completed=completed)
                for i, weight in enumerate(kg_values)
            ]

        values = numbers(line)
        if len(values) >= 4 and values[-1] <= 20:
            return [
                set_record(
                    i + 1,
                    weight=weight,
                    reps=values[-1],
                    side=side,
                    completed=completed,
                )
                for i, weight in enumerate(values[:-1])
            ]
        if len(values) >= 2:
            return [
                set_record(
                    i + 1,
                    weight=values[0],
                    reps=reps,
                    side=side,
                    completed=completed,
                )
                for i, reps in enumerate(values[1:])
            ]
        return [set_record(1, side=side, completed=completed)]

    match = re.search(r"(\d+(?:\.\d+)?)\s*x\s*(\d+)", line, re.I)
    if match:
        reps = float(match.group(1))
        count = int(match.group(2))
        return [
            set_record(i + 1, reps=reps, side=side, completed=completed)
            for i in range(count)
        ]
    values = numbers(re.sub(r"\([^)]*\)", " ", line))
    if values:
        return [
            set_record(i + 1, reps=reps, side=side, completed=completed)
            for i, reps in enumerate(values)
        ]
    return [set_record(1, side=side, completed=completed)]


def convert() -> dict:
    text = SOURCE.read_text(encoding="utf-8").replace("\r\n", "\n")
    records = []
    current = None

    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if re.match(r"^26\.\d{1,2}\.\d{1,2}", line):
            if current:
                records.append(current)
            date = date_from(line)
            status = "未完成" if "没练" in line else "正常"
            current = {
                "id": f"history_{date}",
                "date": date,
                "title": title_from(line),
                "bodyParts": [],
                "status": status,
                "durationMin": None,
                "startedAt": None,
                "finishedAt": None,
                "autoDurationMin": None,
                "note": f"导入自历史训练记录.md：{line}",
                "exercises": [],
                "createdAt": f"{date}T00:00:00",
                "updatedAt": f"{date}T00:00:00",
            }
            continue
        if current is None:
            continue

        clean_line = normalize(line)
        name = find_exercise_name(clean_line)
        if name is None:
            current["note"] += f"\n未结构化：{line}"
            continue

        category, exercise_type, unit, is_unilateral = EXERCISES[name]
        completed = current["status"] != "未完成"
        sets = parse_sets(clean_line, exercise_type, completed)
        note = f"原始记录：{line}"
        if any(
            token in clean_line
            for token in ["痛", "不舒服", "酸", "状态", "不知道", "力竭", "热身", "尝试", "体感"]
        ):
            note += "\n请人工复核：历史记录含主观描述或不确定信息。"

        current["exercises"].append(
            {
                "id": f"history_{current['date']}_ex_{len(current['exercises']) + 1}",
                "name": name,
                "category": category,
                "type": exercise_type,
                "unit": unit,
                "isUnilateral": is_unilateral,
                "sets": sets,
                "note": note,
            }
        )
        if category not in current["bodyParts"]:
            current["bodyParts"].append(category)

    if current:
        records.append(current)

    for record in records:
        if not record["bodyParts"]:
            record["bodyParts"] = ["其他"]
        if record["status"] == "正常" and any(
            ("痛" in exercise.get("note", "") or "酸" in exercise.get("note", ""))
            for exercise in record["exercises"]
        ):
            record["status"] = "疲劳"

    return {
        "schemaVersion": 1,
        "source": "历史训练记录.md",
        "records": records,
    }


if __name__ == "__main__":
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    payload = convert()
    OUTPUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    records = payload["records"]
    exercise_count = sum(len(record["exercises"]) for record in records)
    set_count = sum(
        len(exercise["sets"]) for record in records for exercise in record["exercises"]
    )
    print(f"records={len(records)} exercises={exercise_count} sets={set_count}")
    print(OUTPUT)
