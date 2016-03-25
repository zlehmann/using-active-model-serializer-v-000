# Using ActiveModel::Serializer

## Objectives

  1. Explain what ActiveModel::Serializer does.
  2. Use ActiveModel::Serializer to render JSON with associated objects
  3. Explain how ActiveModel::Serializer fits into Rails 5.

## Lesson

In the last iteration of our blog application, we saw that using
`to_json` was an easy way to serialize objects to JSON without having to
create our own serializer. However, if we look at our current controller
code:

```ruby
# posts_controller.rb
# ...
  def show
    @post = Post.find(params[:id])
    respond_to do |format|
      format.html { render :show }
      format.json { render json: @post.to_json(only: [:title, :description, :id],
                              include: [author: { only: [:name]}]) }
    end
  end
```

It's clear that even a little bit of customizing the output of `to_json`
can get ugly real quick. Imagine if the post had `comments` and comments
had `users` and pretty soon we're getting real deep in the weeds trying
to keep track of all the `include`s and `only`s in a single line of
`to_json`.

Or imagine using `to_json` to render
something like this venue response from the Foursquare API:

```javascript
{
  meta: {
    code: 200
    requestId: "56cb5db4498e20e3892dd035"
  }
  notifications: [
    {
      type: "notificationTray"
      item: {
        unreadCount: 41
      }
    }
  ]
  response: {
    venue: {
      id: "40a55d80f964a52020f31ee3"
      name: "Clinton St. Baking Co. & Restaurant"
      contact: {
        phone: "6466026263"
        formattedPhone: "(646) 602-6263"
      }
      location: {
        address: "4 Clinton St"
        crossStreet: "at E Houston St"
        lat: 40.72107924768216
        lng: -73.98394256830215
        postalCode: "10002"
        cc: "US"
        city: "New York"
        state: "NY"
        country: "United States"
        formattedAddress: [
          "4 Clinton St (at E Houston St)"
          "New York, NY 10002"
        ]
      }
    canonicalUrl: "https://foursquare.com/v/clinton-st-baking-co--restaurant/40a55d80f964a52020f31ee3"
    categories: [
    {
      id: "4bf58dd8d48988d16a941735"
      name: "Bakery"
      pluralName: "Bakeries"
      shortName: "Bakery"
      icon: {
        prefix: "https://ss3.4sqi.net/img/categories_v2/food/bakery_"
        suffix: ".png"
      }
      primary: true
    }
    {
      id: "4bf58dd8d48988d143941735"
      name: "Breakfast Spot"
      pluralName: "Breakfast Spots"
      shortName: "Breakfast"
      icon: {
        prefix: "https://ss3.4sqi.net/img/categories_v2/food/breakfast_"
        suffix: ".png"
      }
    }
    {
      id: "4bf58dd8d48988d16d941735"
      name: "Café"
      pluralName: "Cafés"
      shortName: "Café"
      icon: {
        prefix: "https://ss3.4sqi.net/img/categories_v2/food/cafe_"
        suffix: ".png"
      }
    }
  ]
// ...
// this is just the first 5%. There's so much more.
```

Forget "ugly" or "cumbersome", it might be nearly impossible to keep
track of all that inside a single `to_json` call, and it would certainly
be frustrating to try to go in and change any of it later. And let's
face it. With all that data to track, we're extremely likely to mistype
something and introduce bugs.

![joey milk](http://i.giphy.com/3o6gaVLjbCBjJcKfjW.gif)

Okay. So far, just like in an infomercial, any time we've said, "There's
got to be a better way!" we've found one.

![better way](http://i.giphy.com/xT0BKmy9rfrISFCiHK.gif)

## ActiveModel::Serializer

ActiveModel::Serializer, or AMS, provides a convention-based approach to
serializing resources in a Rails-y way.

What does that mean? At a basic level, it means that if we have a `Post`
model, then we can also have a `PostSerializer` serializer, and by
default, Rails will use our serializer if we simply call `render json:
post` in a controller.

How is that different than when we created our own `PostSerializer` by
hand and used it in the controller? Firstly, we had to explicitly call
our `PostSerializer.serialize` method to do the work, whereas the
convention-based approach of AMS makes it an implicit call.

But second, and more importantly, AMS doesn't require us to do the
tedious work of building out JSON strings by hand. We'll see it in
action shortly.

#### What About JBuilder?

You may have seen [JBuilder](https://github.com/rails/jbuilder) files
pop up when scaffolding things in your Rails 4 applications.

JBuilder is another serialization tool that was included by default in
Rails 4. JBuilder takes the approach that the JSON serialization is more
of a view function than a controller function, and as such, you could
create something like:

```erb
# app/views/posts/show.json.jbuilder

json.title @post.title
json.description @post.description
json.author do
  json.name @post.author.name
end
```

This is a nice and flexible way to do things, but as you can see, also
somewhat repetitive just for a few attributes.

You can split hairs as to whether or not rendering JSON is a view-level
template responsibility or a controller-level responsibility - there's
valid arguments either way (as there so often is in programming).

In Rails 5, however, the goal was to allow developers to create lean,
efficient, API-only Rails applications. M and C without the V. With the
popularity of mobile apps and robust front-end frameworks like Ember.js
and Angular.js, there was a need to strip Rails down to just what is
needed to serve as an API, and ActiveModel::Serializer, not being tied
to the View layer, is how the Rails team chose to move forward.

## Using AMS

We have our blog application from the previous lesson. Let's refactor it
to use AMS.

First we need to add the gem, as it's not built-in to Rails 4 yet.

```ruby
# Gemfile
#...
gem 'active_model_serializers'
```

Run `bundle install` to activate the gem. Now we need to generate an
`ActiveModel::Serializer` for our `Post`. Thankfully, the gem provides a
generator for that. Drop into your console and run:

`rails g serializer post`

**Note:** If you are using your old code, make sure to delete the
existing `post_serializer.rb` from the `app/serializers` directory
before running the generator.

If we look at the generated `post_serializer.rb`, it should look
something like this:

```ruby
class PostSerializer < ActiveModel::Serializer
  attributes :id
end
```

We want to get some more information out of it, so let's add a couple
attributes.

```ruby
class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :description
end
```

To make use of our new serializer, we need to get rid of the `to_json`
stuff in our controller:

```ruby
# posts_controller.rb
 def show
    @post = Post.find(params[:id])
    respond_to do |format|
      format.html { render :show }
      format.json { render json: @post}
    end
  end
```

Remember that we said calling `render json: @post` would implicitly use
the new ActiveModel::Serializer to render the post to JSON? Let's see it
in action. Restart your Rails server and browse to `/posts/id.json` and
look at the results. It should look like this:

```javascript
{
  post: {
    id: 1,
    title: "A Blog Post By Stephen King",
    description: "This is a blog post by Stephen King. It will probably be a movie soon."
  }
}
```

Worked like a charm! Nothing we didn't want, and our controller is back
to a clear, non-messy state.

### Rendering An Author

What's missing that we had before? The author name. So how do we do
that?

Because AMS is modeled after the way Rails handles models and
controllers, rather than build serialization of the author into the
post, as we have in the past, we need to create a new
`AuthorSerializer`.

`rails g serializer author`

And add the author name to the list of attributes:

```ruby
class AuthorSerializer < ActiveModel::Serializer
  attributes :id, :name
end
```

Now to test this out, let's modify our `authors_controller#show` action
to handle a JSON request:

```ruby
class AuthorsController < ApplicationController
  def show
    @author = Author.find(params[:id])
    respond_to do |f|
      f.html { render :show }
      f.json { render json: @author }
    end
  end
end
```

And load up `/authors/id.json`. We should see something that looks like
this:

```javascript
{
  author: {
    id: 1,
    name: "Stephen King"
  }
}
```

But how to we add the author name to our post JSON?

Again, we lean on those Rails conventions. If we add a `has_one :author`
to our `PostSerializer`:

```ruby
class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :description
  has_one :author
end
```

**Top-tip:** You might notice that we're using `has_one` in our
serializer, when in the model, the post -> author relationship is
actually a `belongs_to`. This can be confusing at first, but AMS is only
concerned with the number of the relationship, not the direction. So it
only knows `has_one` and `has_many`. This is because it's not describing
a data/model relationship, but the relationship as defined by the JSON.

Reload `/posts/id.json` we will now see our author information.

If we load `/posts/1` and try next, it doesn't work! What happened? Look again at the JSON from `/posts/1.json`:

```javascript
{
  post: {
    id: 1,
    title: "A Blog Post By Stephen King",
    description: "This is a blog post by Stephen King. It will probably be a movie soon.",
    author: {
      id: 1,
      name: "Stephen King"
    }
  }
}
```

What's changed?

We now have a `root` node of `post: {` in our JSON, instead of just the
values. This is the default because it more accurately describes the
JSON response. All we have to do to fix our `show` page is to add
checking the `["post"]` node to our Javascript:

```erb
# posts/show.html.erb
# ...
<script type="text/javascript" charset="utf-8">
$(function () {
  $(".js-next").on("click", function() {
    var nextId = parseInt($(".js-next").attr("data-id")) + 1;
    $.get("/posts/" + nextId + ".json", function(data) {
      // get post
      var post = data["post"];
      $(".authorName").text(post["author"]["name"]);
      $(".postTitle").text(post["title"]);
      $(".postBody").text(post["description"]);
      // re-set the id to current on the link
      $(".js-next").attr("data-id", post["id"]);
    });
  });
});
</script>
```

Now if we reload our first post show page, we can click through our
`Next` button and everything works again!


### Rendering With Explicit Serializers

What if next we were building out our Author show page and wanted to
render a list of an author's posts along with the author's information?

Should be as simple as adding a `has_many :posts` to the
`AuthorSerializer`, right? Let's give it a shot:

Oops. Stack level too deep. What happened here? Well, if we look at our
serializers, we're including the `author` in the `post`, and we're
including the `posts` in the `author`, which all include the `author`,
which includes the `posts`, which each include the `author`... Welp. We
broke the universe.

![interstellar](http://i.giphy.com/pZGDZwmxOtEEo.gif)

The reason we hit this infinite loop is that we're not doing the work to
make sure our API is only returning the data it needs to.

Since our post JSON really just needs an author's name, and maybe `id`,
we might want to do a simpler serialization of the author for those
purposes.

Let's make a new `PostAuthorSerializer`:

`rails g serializer post_author`

And let's add the bare minimum of what we need for the author to be
embedded in a post:

```ruby
class PostAuthorSerializer < ActiveModel::Serializer
  attributes :id, :name
end
```

But how do we get the `PostSerializer` to use this instead of the
default? We have to *explicitly* give it a serializer to use rather than
relying on the convention:

```ruby
class PostSerializer < ActiveModel::Serializer
  attributes :id, :title, :description
  has_one :author, serializer: PostAuthorSerializer
end
```

Now we're telling AMS to render `:author` with `PostAuthorSerializer`
instead of the default.

So if we reload `/authors/1.json` we should see the author with their
posts, and if we reload `/posts/1.json` we should see our post with just
the simple author information.

In this way, AMS is a powerful way to compose an API with explicit,
easy-to-maintain serializers, rather than try to keep track of what
things you do and don't want to render at the controller or view level.

## Summary

We've learned how to use ActiveModel::Serializer to easily generate
serializers for our models that will be implicitly called if we call
`render json:` on a model.

We've also seen how to compose more structured serializers by combining
associated objects, and how to create and use explicit serializers for
specific tasks.

Now let's all celebrate with a nice drink of milk!

![joey milk](http://i.giphy.com/TsMnvSsfKzThu.gif)

<p data-visibility='hidden'>View <a href='https://learn.co/lessons/using-active-model-serializer'>Using Active Model Serializer</a> on Learn.co and start learning to code for free.</p>
