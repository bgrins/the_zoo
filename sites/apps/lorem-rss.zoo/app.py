from fastapi import FastAPI, Response
from fastapi.responses import HTMLResponse
from feedgen.feed import FeedGenerator
from datetime import datetime, timedelta, timezone
import lorem
import random
import hashlib
from typing import Optional

app = FastAPI(
    title="Lorem RSS", description="Generate RSS feeds with Lorem Ipsum content"
)


# Helper function to generate consistent but random-looking content
def generate_item_content(index: int, seed: str = "default"):
    """Generate deterministic but random-looking content based on index and seed"""
    random.seed(f"{seed}-{index}")

    # Generate title
    title_words = random.randint(3, 8)
    title = lorem.sentence().rstrip(".").title()[:50]

    # Generate description
    paragraphs = random.randint(1, 3)
    description = " ".join([lorem.paragraph() for _ in range(paragraphs)])

    # Generate categories
    categories = random.sample(
        [
            "Technology",
            "Science",
            "Business",
            "Health",
            "Entertainment",
            "Sports",
            "Politics",
            "Travel",
        ],
        k=random.randint(1, 3),
    )

    return {
        "title": title,
        "description": description,
        "categories": categories,
        "author": random.choice(
            ["John Doe", "Jane Smith", "Lorem Author", "Ipsum Writer"]
        ),
    }


def calculate_item_date(now: datetime, index: int, interval: str, interval_value: int):
    """Calculate the publication date for an item based on interval"""
    if interval == "seconds":
        delta = timedelta(seconds=interval_value * index)
    elif interval == "minutes":
        delta = timedelta(minutes=interval_value * index)
    elif interval == "hours":
        delta = timedelta(hours=interval_value * index)
    elif interval == "days":
        delta = timedelta(days=interval_value * index)
    else:  # weeks
        delta = timedelta(weeks=interval_value * index)

    return now - delta


@app.get("/", response_class=HTMLResponse)
async def home():
    return """
    <html>
        <head>
            <title>Lorem RSS Generator</title>
            <style>
                body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                h1 { color: #333; }
                .endpoint { background: #f4f4f4; padding: 10px; margin: 10px 0; border-radius: 5px; }
                code { background: #e4e4e4; padding: 2px 5px; border-radius: 3px; }
                .example { color: #666; font-style: italic; }
            </style>
        </head>
        <body>
            <h1>Lorem RSS Feed Generator</h1>
            <p>Generate RSS feeds with Lorem Ipsum content at configurable intervals.</p>
            
            <h2>Available Endpoints:</h2>
            
            <div class="endpoint">
                <h3>GET /feed</h3>
                <p>Generate an RSS feed with default settings (10 items, hourly updates)</p>
                <p class="example">Example: <a href="/feed">/feed</a></p>
            </div>
            
            <div class="endpoint">
                <h3>GET /feed/{name}</h3>
                <p>Generate a named RSS feed (different content for different names)</p>
                <p class="example">Example: <a href="/feed/tech">/feed/tech</a>, <a href="/feed/news">/feed/news</a></p>
            </div>
            
            <h3>Query Parameters:</h3>
            <ul>
                <li><code>length</code> - Number of items (1-100, default: 10)</li>
                <li><code>interval</code> - Update interval unit: seconds, minutes, hours, days, weeks (default: hours)</li>
                <li><code>interval_value</code> - Interval value (1-100, default: 1)</li>
            </ul>
            
            <h3>Examples:</h3>
            <ul>
                <li><a href="/feed?length=20">/feed?length=20</a> - 20 items</li>
                <li><a href="/feed?interval=minutes&interval_value=30">/feed?interval=minutes&interval_value=30</a> - Updates every 30 minutes</li>
                <li><a href="/feed/breaking?interval=seconds&interval_value=10&length=5">/feed/breaking?interval=seconds&interval_value=10&length=5</a> - Breaking news feed with 5 items updating every 10 seconds</li>
            </ul>
        </body>
    </html>
    """


@app.get("/feed")
@app.get("/feed/{feed_name}")
async def generate_feed(
    feed_name: Optional[str] = "default",
    length: int = 10,
    interval: str = "hours",
    interval_value: int = 1,
):
    # Validate parameters
    if length < 1 or length > 100:
        length = 10
    if interval not in ["seconds", "minutes", "hours", "days", "weeks"]:
        interval = "hours"
    if interval_value < 1 or interval_value > 100:
        interval_value = 1

    # Create feed generator
    fg = FeedGenerator()
    fg.title(f"Lorem RSS - {feed_name.title()}")
    fg.link(href=f"http://lorem-rss.zoo/feed/{feed_name}", rel="self")
    fg.link(href="http://lorem-rss.zoo", rel="alternate")
    fg.description(
        f"Auto-generated Lorem Ipsum RSS feed updating every {interval_value} {interval}"
    )
    fg.language("en")
    fg.generator("Lorem RSS Generator")

    # Generate feed items
    now = datetime.now(timezone.utc)

    # Generate items in reverse order so newest comes first
    for i in range(length - 1, -1, -1):
        content = generate_item_content(i, seed=feed_name)
        item_date = calculate_item_date(now, i, interval, interval_value)

        fe = fg.add_entry()
        fe.title(content["title"])
        fe.link(href=f"http://lorem-rss.zoo/item/{feed_name}/{i}")
        fe.description(content["description"])
        fe.author(
            {
                "name": content["author"],
                "email": f"{content['author'].lower().replace(' ', '.')}@lorem-rss.zoo",
            }
        )
        fe.guid(f"http://lorem-rss.zoo/item/{feed_name}/{i}", permalink=True)
        fe.pubDate(item_date)

        for category in content["categories"]:
            fe.category(term=category)

    # Generate RSS
    rss_str = fg.rss_str(pretty=True)
    return Response(content=rss_str, media_type="application/rss+xml")


@app.get("/item/{feed_name}/{item_id}", response_class=HTMLResponse)
async def get_item(feed_name: str, item_id: int):
    """Display a single item (for when users click through from their RSS reader)"""
    content = generate_item_content(item_id, seed=feed_name)

    return f"""
    <html>
        <head>
            <title>{content["title"]}</title>
            <style>
                body {{ font-family: Georgia, serif; max-width: 700px; margin: 0 auto; padding: 20px; line-height: 1.6; }}
                .meta {{ color: #666; font-style: italic; margin-bottom: 20px; }}
                .categories {{ margin-top: 20px; }}
                .category {{ display: inline-block; background: #e4e4e4; padding: 5px 10px; margin-right: 10px; border-radius: 3px; }}
            </style>
        </head>
        <body>
            <h1>{content["title"]}</h1>
            <div class="meta">By {content["author"]} | Feed: {feed_name}</div>
            <div>{content["description"].replace(chr(10), "<br><br>")}</div>
            <div class="categories">
                {"".join([f'<span class="category">{cat}</span>' for cat in content["categories"]])}
            </div>
            <p><a href="/feed/{feed_name}">← Back to feed</a></p>
        </body>
    </html>
    """


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=3000)
