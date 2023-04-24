require "graphql/client"
require "graphql/client/http"

module Formfunction
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("https://formfunction.hasura.app/v1/graphql") do
    def headers(_context)
      # Optionally set any HTTP headers
      { 'User-Agent': "@richjard (please don't block me :))" }
    end
  end

  # Fetch latest schema on init, this will make a network request
  # Schema = GraphQL::Client.load_schema(HTTP)
  # GraphQL::Client.dump_schema(Formfunction::HTTP, "schema.json")

  # However, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task
  # GraphQL::Client.dump_schema(SWAPI::HTTP, "path/to/schema.json")
  #
  Schema = GraphQL::Client.load_schema("schema.json")

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
