require 'redis_collection/version'
require 'set'
require 'benchmark'

class RedisCollection
  def initialize(redis,
    namespace: '',
    load:     -> string { Marshal.load(string) },
    dump:     -> object { Marshal.dump(object) },
    make_key: -> object { object['id'] }
  )

    @redis         = redis
    @namespace     = namespace
    @load_proc     = load
    @dump_proc     = dump
    @make_key_proc = make_key

    clear_args
  end

  attr_reader :redis, :namespace, :load_proc, :dump_proc, :make_key_proc

  ##
  # Sync values under a redis namespace with the given collection by
  #
  #   - overwriting existing values
  #   - deleting what's not in collection
  #
  def sync(collection)
    clear_args
    updated_namespaced_keys = Set.new

    each_with_key(collection) do |object, key|
      updated_namespaced_keys << "#{namespace}#{key}"
      add_mset "#{namespace}#{key}", dump(object)
    end

    redis.scan_each(match: "#{namespace}*") do |namespaced_key|
      unless updated_namespaced_keys.include?(namespaced_key)
        add_del namespaced_key
      end
    end

    exec!
  end

  private

  def exec!
    stats = {
      mset_cnt: @mset_args.size / 2,
      del_cnt:  @del_args.size
    }

    stats[:time] = Benchmark.measure {
      redis.multi do |multi|
        multi.mset(*@mset_args) unless @mset_args.empty?
        multi.del(*@del_args)   unless @del_args.empty?
      end
    }

    stats
  end

  def each_with_key(collection)
    collection.each do |object|
      yield object, make_key(object)
    end
  end

  def add_mset(key, value)
    @mset_args << key << value
  end

  def add_del(key)
    @del_args << key
  end

  def load(string)
    load_proc.(string)
  end

  def dump(object)
    dump_proc.(object)
  end

  def make_key(object)
    make_key_proc.(object)
  end

  private

  def clear_args
    @mset_args = []
    @del_args  = []
  end
end
