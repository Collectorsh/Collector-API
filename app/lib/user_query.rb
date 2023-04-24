module UserQuery
  User = Formfunction::Client.parse <<-'GRAPHQL'
    query($username: String!) {
      User(where: {username: {_eq: $username}}) {
        twitterName
      }
    }
  GRAPHQL
end
