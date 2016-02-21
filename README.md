# Using Active Model Serializer

## Objectives

  1. Understand what AMS does
  2. Use AMS to render JSON with associated objects
  3. Understand how AMS fits into Rails 5

## Outline

  * So you have all of the Post stuff working for you blog. Let's work on Author now
  * Still in `to_json` create a `/posts/1.json` route that spits out the json
  * Then modify it to just spit out the interesting bits
  * Oh hey! we want to spit out the author and all of their posts. Do that with `to_json`
  * No in the post we only want to show the interesting things
  * So complicated. So ugly. Show the JSON result for a foursquare venue and be like "LOOK HOW TERRIBLE THIS WOULD BE WITH TO_JSON"
  * Introduce AMS.
  * Explain the JBuilder was a thing, but in Rails 5 a big push is to make Rails great for APIs. Changed to a more flexible AMS
  * Explain AMS is a bunch of serializers.
  * Show just rendering the Post, just rendering the Author
  * Show how to embed the posts in the Author
