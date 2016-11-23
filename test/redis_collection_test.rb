require 'test_helper'

class RedisCollectionTest < Minitest::Test
  def read_namespace(namespace = '')
    keys = @redis.scan_each(match: "#{namespace}*").to_a
    @redis.mget(*keys)
  end

  def setup
    @redis = MockRedis.new
    @books = [
      {'id' => 1, 'title' => 'Programming Elixir'},
      {'id' => 2, 'title' => 'Programming Phoenix'}
    ]
  end

  def test_syncs_objects
    rc = RedisCollection.new(@redis)
    rc.sync(@books)
    assert_equal @books, read_namespace.map{|s| Marshal.load(s)}
  end

  def test_namespaces_redis_keys
    rc = RedisCollection.new(@redis, namespace: 'foo_')
    rc.sync(@books)
    assert_equal @books, read_namespace('foo_').map{|s| Marshal.load(s)}
  end

  def test_allows_custom_dump_load
    rc = RedisCollection.new(@redis,
      dump: -> obj { obj.to_s },
      load: -> str { eval(str) }
    )

    rc.sync(@books)
    assert_equal [
      "{\"id\"=>1, \"title\"=>\"Programming Elixir\"}",
      "{\"id\"=>2, \"title\"=>\"Programming Phoenix\"}"
    ], read_namespace
  end

  def test_allows_custom_key
    rc = RedisCollection.new(@redis, make_key: -> obj {obj['id'] + 5})
    rc.sync(@books)
    assert_equal @books[0], Marshal.load(@redis.get(6))
  end

  def test_overwrites_synced_objects
    rc = RedisCollection.new(@redis)
    rc.sync(@books)

    new_books = [
      {'id' => 1, 'title' => 'Programming Elixir'},
      {'id' => 2, 'title' => 'Programming Ruby'}
    ]

    rc.sync(new_books)
    assert_equal new_books, read_namespace.map{|s| Marshal.load(s)}
  end

  def test_deletes_extra_objects
    rc = RedisCollection.new(@redis)
    rc.sync(@books)
    new_books = [{'id' => 1, 'title' => 'Programming Elixir'}]
    rc.sync(new_books)
    assert_equal new_books, read_namespace.map{|s| Marshal.load(s)}
  end

  def test_returns_correct_mset_cnt
    rc = RedisCollection.new(@redis)
    stats = rc.sync(@books)
    assert_equal 2, stats[:mset_cnt]
  end

  def test_returns_correct_del_cnt
    rc = RedisCollection.new(@redis)
    stats = rc.sync(@books)
    assert_equal 0, stats[:del_cnt]
    stats = rc.sync([{'id' => 1, 'title' => 'Programming Elixir'}])
    assert_equal 1, stats[:del_cnt]
  end

  def test_returns_benchmark_result
    rc = RedisCollection.new(@redis)
    stats = rc.sync(@books)
    assert stats[:time].is_a?(Benchmark::Tms)
  end

  def test_resets_stats_on_each_sync
    rc = RedisCollection.new(@redis)
    stats = rc.sync(@books)
    stats = rc.sync(@books)
    assert_equal 2, stats[:mset_cnt]
  end

  # def test_that_it_has_a_version_number
  #   refute_nil ::RedisCollection::VERSION
  # end

  # def test_it_does_something_useful
  #   assert false
  # end
end
