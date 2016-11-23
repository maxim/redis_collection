# RedisCollection

Easily sync an iterable ruby object with a redis namespace.

This tool DOES NOT:

- integrate with anything
- help retrieve data back from redis
- handle redis connection issues
- make birds in 5 mile radius attack you

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis_collection'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis_collection

## Usage

```ruby
books = [
  { 'id' => 1, 'title' => 'Programming Elixir' },
  { 'id' => 2, 'title' => 'Programming Phoenix' }
]

redis = Redis.new(url: ENV['REDIS_URL'])
redis_collection = RedisCollection.new(redis, namespace: 'books_')
redis_collection.sync(books)
redis.mget('books_1', 'books_2')
# => ["\x04\b{\aI\"\aid\x06:\x06ETi\x06I\"\ntitle\x06;\x00TI\"\x17Programming Elixir\x06;\x00T", "\x04\b{\aI\"\aid\x06:\x06ETi\aI\"\ntitle\x06;\x00TI\"\x18Programming Phoenix\x06;\x00T"]
```

By default each object in the collection is serialized via `Marshal.dump` and loaded via `Marshal.load`. Identity of each object is determined by calling `['id']` by default. To change these defaults you can provide procs to `RedisCollection.new`.

```ruby
redis_collection = RedisCollection.new(redis,
  namespace: 'books_',
  load: -> string { JSON.parse(string) },
  dump: -> object { object.to_json },
  make_key: -> object { object.special_id }
)
redis_collection.sync(books)
```

In the above example objects are converted to/from JSON and must respond to `special_id` to be identified.

Method `sync` always overwrites keys that already exist in Redis, and deletes keys that are in Redis but not in collection.

## Benchmark

Method `sync` returns a hash of stats containing 3 pieces of information:

1. `:mset_cnt` - how many strings were [mset](http://redis.io/commands/mset)
2. `:del_cnt` - how many strings were [del](http://redis.io/commands/del)
3. `:time` - the result of `Benchmark.measure {}` on the redis call

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/crossfield/redis_collection. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
