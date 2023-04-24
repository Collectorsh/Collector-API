require "graphql/client"
require "graphql/client/http"

module Holaplex
  # Configure GraphQL endpoint using the basic HTTP network adapter.
  HTTP = GraphQL::Client::HTTP.new("https://graph.holaplex.com/v1")

  # Fetch latest schema on init, this will make a network request
  Schema = GraphQL::Client.load_schema(HTTP)
  # GraphQL::Client.dump_schema(Holaplex::HTTP, "holaplex_schema.json")

  # However, it's smart to dump this to a JSON file and load from disk
  #
  # Run it from a script or rake task
  # GraphQL::Client.dump_schema(SWAPI::HTTP, "path/to/schema.json")
  #
  Schema = GraphQL::Client.load_schema("holaplex_updated.json")

  Client = GraphQL::Client.new(schema: Schema, execute: HTTP)
end
