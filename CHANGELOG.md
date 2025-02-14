# Changelog for Ecto.Adapters.DynamoDB v3.x.x

[v2.x.x -> v3.x.x upgrade guide](/upgrade_guides/version_3_upgrade_guide.md)

## v3.3.0

- Add support for table stream configuration

## v3.2.0

- Fix migrations support for ecto_sql 3.7.2
- Fix warnings on Elixir 1.13
- Raise minimum Elixir version to 1.10
- Add dialyzer run to CI workflow

## v3.1.3

- Support `:empty_mapset_to_nil` for `insert_all` function
- Fix error decoding parameterized field on schema load

## v3.1.2

- Support update operations for the `:empty_map_set_to_nil` option.

## v3.1.1

- Support for `ecto_sql` version 3.6.

## v3.1.0

- Add `:nil_to_empty_mapset` and `:empty_mapset_to_nil` configuration options.

## v3.0.3

- Constrain ecto_sql requirement to 3.5.x. 3.6 introduces interface changes that are not yet supported.

## v3.0.2

- Add handling for `nil` values in `DynamoDBSet.is_equal?`

## v3.0.1

- Maintain backwards compatibility for Ecto versions 3.0 <= 3.4 - all major version 3 releases of Ecto should now be supported

## v3.0.0

### Enhancements

#### Configuration

- Per-repo configuration support

#### Dependencies

- Upgrade to and support for [Ecto](https://github.com/elixir-ecto/ecto) version 3.5 or higher (lower versions not supported by this release)
- Upgrade [ExAws.Dynamo](https://github.com/ex-aws/ex_aws_dynamo) to version 4 - recommend reviewing upgrade guide in that repo
- Upgrade Hackney to v1.17.3
