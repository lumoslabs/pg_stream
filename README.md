# PgStream

PgStream allows you to stream data from Postgres or Redshift, and provides a framework to help you process it. Normally, Postgres and Redshift collect the entire result set in memory and then return it to you at once. PgStream allows you to process the result row by row, which may be the only way to handle very large results.

## Requirements

You must be using PostgreSQL 9.2beta3 or later client libraries. You must be using pg 0.18.2 or later.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_stream'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pg_stream

## Usage

To get started, just pass it a PG::Connection and a query body string:

```ruby
require 'pg'

body = 'SELECT * FROM huge_table;'

conn = PG::Connection.open(:dbname => 'test')

query_stream = PgStream::Stream.new(conn, body)
```

You can consume directly from the stream by calling `headers` and `each_row`:

```ruby
CSV.open('some_filepath', 'w') do |csv|
  csv << query_stream.headers
  query_stream.each_row do |row|
    csv << row
  end
end
```

Or if you have multiple things that need the data you may use the Processor to consume the data from the db. The processor will register `before_execute`, `during_execute` and `after_execute` callbacks. The processor yields the `row` and `row_count` to the `during_execute` callback, and the `row_count` to the `after_execute` callback.

```ruby
stream_processor = PgStream::Processor.new(query_stream)

def setup_csv
  lambda do
    @csv = CSV.open('some_filepath', 'w')
    @csv << headers
  end
end

stream_processor.register(
  {
    before_execute: setup_csv,
    during_execute: ->(row, _row_count) { @csv << row },
    after_execute: ->(_row_count) { @csv.close }
  }
)

def collect_sample
  @sample = []
  lambda do |row, row_count|
    @sample << row if row_count <= 100
  end
end

stream_processor.register(during_execute: collect_sample)
```

You may call register multiple times on a single Processor.

To make the Processor run and yield to your callbacks, just call `execute` on it. It will return the row_count when it is done. Keep in mind this may take seconds or minutes depending on the size of your result, so you will probably want to do this in a background job.

```
row_count = stream_processor.execute
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/pg_stream/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
