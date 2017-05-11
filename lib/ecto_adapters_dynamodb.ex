defmodule Ecto.Adapters.DynamoDB do
  @moduledoc """
  Ecto adapter for Amazon DynamoDB

  Currently fairly limited subset of Ecto, enough for basic operations.

  NOTE: in ecto, Repo.get[!] ends up calling: 
    -> querable.get
    -> queryable.one
    -> queryable.all
    -> queryable.execute
    -> adapter.execute (possibly prepare somewhere in their too? trace.)


  """



  @behaviour Ecto.Adapter
  #@behaviour Ecto.Adapter.Storage
  #@behaviour Ecto.Adapter.Migration

  defmacro __before_compile__(_env) do
    # Nothing to see here, yet...

  end

  alias ExAws.Dynamo

  # I don't think this is necessary: Probably under child_spec and ensure_all_started
  def start_link(repo, opts) do
    IO.puts("start_link repo: #{inspect repo} opts: #{inspect opts}")
    Agent.start_link fn -> [] end
  end


  ## Adapter behaviour - defined in lib/ecto/adapter.ex (in the ecto github repository)

  @doc """
  Returns the childspec that starts the adapter process.
  """
  def child_spec(repo, opts) do
    # TODO: need something here...
    # * Pull dynamo db connection options from config
    # * Start dynamo connector/aws libraries
    # we'll return our own start_link for now, but I don't think we actually need
    # an app here, we only need to ensure that our dependencies such as aws libs are started.
    # 
    import Supervisor.Spec
    child_spec = worker(__MODULE__, [repo, opts])
    IO.puts("child spec3. REPO: #{inspect repo}\n CHILD_SPEC: #{inspect child_spec}\nOPTS: #{inspect opts}")
    child_spec
  end


  @doc """
  Ensure all applications necessary to run the adapter are started.
  """
  def ensure_all_started(repo, type) do
    IO.puts("ensure all started: type: #{inspect type} #{inspect repo}")
    {:ok, [repo]}
  end


# moved to transaction.ex in ecto 2.1.4
#  def in_transaction?(_repo), do: false
#
#  def rollback(_repo, _value), do:
#    raise BadFunctionError, message: "#{inspect __MODULE__} does not support transactions."


  @doc """
  Called to autogenerate a value for id/embed_id/binary_id.

  Returns the autogenerated value, or nil if it must be
  autogenerated inside the storage or raise if not supported.
  """

  def autogenerate(:id), do: Ecto.UUID.bingenerate()
  def autogenerate(:embed_id), do: Ecto.UUID.generate()
  def autogenerate(:binary_id), do: Ecto.UUID.bingenerate()

  @doc """
  Returns the loaders for a given type.

  It receives the primitive type and the Ecto type (which may be
  primitive as well). It returns a list of loaders with the given
  type usually at the end.

  This allows developers to properly translate values coming from
  the adapters into Ecto ones. For example, if the database does not
  support booleans but instead returns 0 and 1 for them, you could
  add:

    def loaders(:boolean, type), do: [&bool_decode/1, type]
    def loaders(_primitive, type), do: [type]

    defp bool_decode(0), do: {:ok, false}
    defp bool_decode(1), do: {:ok, true}

  All adapters are required to implement a clause for `:binary_id` types,
  since they are adapter specific. If your adapter does not provide binary
  ids, you may simply use Ecto.UUID:

    def loaders(:binary_id, type), do: [Ecto.UUID, type]
    def loaders(_primitive, type), do: [type]

  """
  def loaders(_primative, type), do: [type]



  @doc """
  Returns the dumpers for a given type.

  It receives the primitive type and the Ecto type (which may be
  primitive as well). It returns a list of dumpers with the given
  type usually at the beginning.

  This allows developers to properly translate values coming from
  the Ecto into adapter ones. For example, if the database does not
  support booleans but instead returns 0 and 1 for them, you could
  add:

    def dumpers(:boolean, type), do: [type, &bool_encode/1]
    def dumpers(_primitive, type), do: [type]

    defp bool_encode(false), do: {:ok, 0}
    defp bool_encode(true), do: {:ok, 1}

  All adapters are required to implement a clause or :binary_id types,
  since they are adapter specific. If your adapter does not provide
  binary ids, you may simply use Ecto.UUID:

    def dumpers(:binary_id, type), do: [type, Ecto.UUID]
    def dumpers(_primitive, type), do: [type]

  """
  def dumpers(:utc_datetime, datetime) do
    [datetime, &to_iso_string/1]
  end

  def dumpers(_primative, type), do: [type]

  defp to_iso_string(datetime) do
    {:ok, datetime |> Ecto.DateTime.load |> elem(1) |> Ecto.DateTime.to_iso8601}
  end


  @doc """
  Commands invoked to prepare a query for `all`, `update_all` and `delete_all`.

  The returned result is given to `execute/6`.
  """
  #@callback prepare(atom :: :all | :update_all | :delete_all, query :: Ecto.Query.t) ::
  #          {:cache, prepared} | {:nocache, prepared}
  def prepare(:all, query) do
    # 'preparing' is more a SQL concept - Do we really need to do anything here or just pass the params through?
    IO.puts("PREPARE:::")
    IO.inspect(query, structs: false)
    {:nocache, query}
  end
  
  def prepare(:update_all, query) do
    IO.puts("PREPARE::UPDATE_ALL:::")
    IO.inspect(query, structs: false)
    {:nocache, query}
  end
  
  # do: {:cache, {System.unique_integer([:positive]), @conn.update_all(query)}}
  #def prepare(:delete_all, query),
  # do: {:cache, {System.unique_integer([:positive]), @conn.delete_all(query)}}



  @doc """
  Executes a previously prepared query.

  It must return a tuple containing the number of entries and
  the result set as a list of lists. The result set may also be
  `nil` if a particular operation does not support them.

  The `meta` field is a map containing some of the fields found
  in the `Ecto.Query` struct.

  It receives a process function that should be invoked for each
  selected field in the query result in order to convert them to the
  expected Ecto type. The `process` function will be nil if no
  result set is expected from the query.
  """
  #@callback execute(repo, query_meta, query, params :: list(), process | nil, options) :: result when
  #          result: {integer, [[term]] | nil} | no_return,
  #          query: {:nocache, prepared} |
  #                 {:cached, (prepared -> :ok), cached} |
  #                 {:cache, (cached -> :ok), prepared}
  # TODO: What about dynamo db batch_get_item for sql 'where x in [1,2,3,4]' style queries?
  def execute(_repo, _meta, {:nocache, prepared}, params, _process = nil, opts) do
    #Logger.error "EXECUTE... EXECUTING!"
    IO.puts "EXECUTE:::"
    IO.puts "prepared: #{inspect prepared, structs: false}"
    IO.puts "params:   #{inspect params, structs: false}"
    IO.puts "opts:     #{inspect opts, structs: false}"

    {table, model} = prepared.from
    lookup_keys = extract_lookup_keys(:update_all, prepared)
    update_params = extract_update_params(prepared.updates, params)
    key_list = Ecto.Adapters.DynamoDB.Info.primary_key!(table)

    IO.puts "table = #{inspect table}"
    IO.puts "lookup keys: #{inspect lookup_keys}"
    IO.puts "update_params: #{inspect update_params}"
    IO.puts "key_list: #{inspect key_list}"

    case prepared.updates do
      [] -> error "#{inspect __MODULE__}.execute: Updates list empty."
      _  -> 
        results_to_update = Ecto.Adapters.DynamoDB.Query.get_item(table, lookup_keys)
        IO.puts "results_to_update: #{inspect results_to_update}"
        update_all(table, key_list, results_to_update, update_params, model)
    end

    #error "#{inspect __MODULE__}.execute is not implemented."

    #num = 0
    #rows = []
    #{num, rows}
  end


  def execute(repo, meta, {:nocache, prepared}, params, process, opts) do
    IO.puts "EXECUTE... EXECUTING!============================="
    IO.puts "REPO::: #{inspect repo, structs: false}"
    IO.puts "META::: #{inspect meta, structs: false}"
    IO.puts "PREPARED::: #{inspect prepared, structs: false}"
    IO.puts "PARAMS::: #{inspect params, structs: false}"
    IO.puts "PROCESS::: #{inspect process, structs: false}"
    IO.puts "OPTS::: #{inspect opts, structs: false}"

    {table, repo} = prepared.from
    lookup_keys = extract_lookup_keys(:process_not_nil, prepared, params)

    IO.puts "table = #{inspect table}"
    IO.puts "lookup_keys = #{inspect lookup_keys}"

    result = Ecto.Adapters.DynamoDB.Query.get_item(table, lookup_keys)
    IO.puts "result = #{inspect result}"

    if result == %{} do
      # Empty map means "not found"
      {0, []}
    else
      # TODO handle queries for more than just one item? -> Yup, like Repo.get_by, which could call a secondary index.
      case result["Count"] do
        nil   -> {1, [[Dynamo.decode_item(result, as: repo)]]}
        # Repo.get_by only returns the head of the result list, although we could perhaps
        # support multiple wheres to filter the result list further?
        count -> {count, [[Dynamo.decode_item(hd(result["Items"]), as: repo)]]}
      end
    end
  end


  # :update_all for only one result
  defp update_all(table, key_list, %{"Item" => result_to_update}, update_params, model) do
    filters = get_key_values_dynamo_map(result_to_update, key_list)
    update_expression = construct_set_statement(update_params)
    attribute_names = construct_expression_attribute_names(update_params)

    case Dynamo.update_item(table, filters, expression_attribute_names: attribute_names, expression_attribute_values: update_params, update_expression: update_expression, return_values: :all_new) |> ExAws.request! do
      %{} = update_query_result -> {1, [Dynamo.decode_item(update_query_result["Attributes"], as: model)]}
      error -> raise "#{inspect __MODULE__}.update_all, single item, error: #{inspect error}"
    end 
  end

  # :update_all for multiple results
  defp update_all(table, key_list, %{"Items" => results_to_update}, update_params, model) do
    Enum.reduce results_to_update, {0, []}, fn(result_to_update, acc) ->
      filters = get_key_values_dynamo_map(result_to_update, key_list)
      update_expression = construct_set_statement(update_params)
      attribute_names = construct_expression_attribute_names(update_params)

      case Dynamo.update_item(table, filters, expression_attribute_names: attribute_names, expression_attribute_values: update_params, update_expression: update_expression, return_values: :all_new) |> ExAws.request! do
        %{} = update_query_result -> 
          {count, result_list} = acc
          {count + 1, [Dynamo.decode_item(update_query_result["Attributes"], as: model) | result_list]}
        error -> 
          {count, _} = acc
          raise "#{inspect __MODULE__}.update_all, multiple items. Error: #{inspect error} filters: #{inspect filters} update_expression: #{inspect update_expression} attribute_names: #{inspect attribute_names} Count: #{inspect count}" 
      end
    end
  end


  @doc """
  Inserts a single new struct in the data store.

  ## Autogenerate

  The primary key will be automatically included in `returning` if the
  field has type `:id` or `:binary_id` and no value was set by the
  developer or none was autogenerated by the adapter.
  """
  #@callback insert(repo, schema_meta, fields, on_conflict, returning, options) ::
  #                  {:ok, fields} | {:invalid, constraints} | no_return
  #  def insert(_,_,_,_,_) do
  def insert(repo, schema_meta, fields, on_conflict, returning, options) do
    IO.puts("INSERT::\n\trepo: #{inspect repo}")
    IO.puts("\tschema_meta: #{inspect schema_meta}")
    IO.puts("\tfields: #{inspect fields}")
    IO.puts("\ton_conflict: #{inspect on_conflict}")
    IO.puts("\treturning: #{inspect returning}")
    IO.puts("\toptions: #{inspect options}")

    {_, table} = schema_meta.source     
    fields_map = Enum.into(fields, %{}) 

    case Dynamo.put_item(table, fields_map) |> ExAws.request! do
      %{}   -> {:ok, []}
      error -> raise "Error inserting into DynamoDB. Error: #{inspect error}"
    end
  end


  def insert_all(repo, schema_meta, field_list, fields, on_conflict, returning, options) do
    IO.puts("INSERT ALL::\n\trepo: #{inspect repo}")
    IO.puts("\tschema_meta: #{inspect schema_meta}")
    IO.puts("\tfield_list: #{inspect field_list}")
    IO.puts("\tfields: #{inspect fields}")
    IO.puts("\ton_conflict: #{inspect on_conflict}")
    IO.puts("\treturning: #{inspect returning}")
    IO.puts("\toptions: #{inspect options}")

    {_, table} = schema_meta.source

    prepared_fields = Enum.map(fields, fn(field_set) ->
      mapped_fields = Enum.into(field_set, %{})
      [put_request: [item: mapped_fields]]
    end)

    case batch_write_attempt = Dynamo.batch_write_item([{table, prepared_fields}]) |> ExAws.request! do
      # THE FORMAT OF A SUCCESSFUL BATCH INSERT IS A MAP THAT WILL INCLUDE A MAP OF ANY UNPROCESSED ITEMS
      %{"UnprocessedItems" => %{}} ->
        cond do
          # IDEALLY, THERE ARE NO UNPROCESSED ITEMS - THE MAP IS EMPTY
          batch_write_attempt["UnprocessedItems"] == %{} ->
            {:ok, []}
          # TO DO: DEVELOP A STRATEGY FOR HANDLING UNPROCESSED ITEMS.
          # DOCS SUGGEST GATHERING THEM UP AND TRYING ANOTHER BATCH INSERT AFTER A SHORT DELAY
        end
      error -> raise "Error batch inserting into DynamoDB. Error: #{inspect error}"
    end
  end


  # In testing, 'filters' contained only the primary key and value 
  # TODO: handle cases of more than one tuple in 'filters'?
  def delete(repo, schema_meta, filters, options) do
    IO.puts("DELETE::\n\trepo: #{inspect repo}")
    IO.puts("\tschema_meta: #{inspect schema_meta}")
    IO.puts("\tfilters: #{inspect filters}")
    IO.puts("\toptions: #{inspect options}")

    {_, table} = schema_meta.source

    case Dynamo.delete_item(table, filters) |> ExAws.request! do
      %{} -> {:ok, []}
      error -> raise "Error deleting in DynamoDB. Error: #{inspect error}"
    end
  end


  # Again we rely on filters having the correct primary key value.
  # TODO: any aditional checks missing here?
  def update(repo, schema_meta, fields, filters, returning, options) do
    IO.puts("UPDATE::\n\trepo: #{inspect repo}")
    IO.puts("\tschema_meta: #{inspect schema_meta}")
    IO.puts("\tfields: #{inspect fields}")
    IO.puts("\tfilters: #{inspect filters}")
    IO.puts("\treturning: #{inspect returning}")
    IO.puts("\toptions: #{inspect options}")

    {_, table} = schema_meta.source
    update_expression = construct_set_statement(fields)
    attribute_names = construct_expression_attribute_names(fields)
 
    case Dynamo.update_item(table, filters, expression_attribute_names: attribute_names, expression_attribute_values: fields, update_expression: update_expression) |> ExAws.request! do
      %{} -> {:ok, []}
      error -> raise "Error updating item in DynamoDB. Error: #{inspect error}"
    end
  end

  # Used in update_all
  def extract_update_params([], _params), do: error "#{inspect __MODULE__}.extract_update_params: Updates list is empty."
  
  def extract_update_params([%{expr: key_list}], params) do
    case List.keyfind(key_list, :set, 0) do
      {_, set_list} ->
        for s <- set_list, into: [] do
          {field_atom, {:^, _, [idx]}} = s
          {field_atom, Enum.at(params,idx)}
        end
      _ -> error "#{inspect __MODULE__}.extract_update_params: Updates query :expr key list does not contain a :set key." 
    end
  end

  def extract_update_params([a], _params), do: error "#{inspect __MODULE__}.extract_update_params: Updates is either missing the :expr key or does not contain a struct or map: #{inspect a}"
  def extract_update_params(_, _params), do: error "#{inspect __MODULE__}.extract_update_params: More than one Ecto.Query.QueryExpr is not supported."


  # used in :update_all
  def get_key_values_dynamo_map(dynamo_map, {:primary, keys}) do
    # We assume that keys will be labled as "S" (String)
    for k <- keys, into: [], do: {String.to_atom(k), dynamo_map[k]["S"]}
  end


  defp construct_expression_attribute_names(fields) do
    for {f, _} <- fields, into: %{}, do: {"##{Atom.to_string(f)}", Atom.to_string(f)}
  end

  # fields::[{:field, val}]
  defp construct_set_statement(fields) do
    key_val_string = Enum.map(fields, fn {key, _} -> "##{Atom.to_string(key)}=:#{Atom.to_string(key)}" end)
    "SET " <> Enum.join(key_val_string, ", ")
  end


  defp extract_lookup_keys(:update_all, query) do
    for w <- query.wheres, into: %{} do
      get_eq_clause(:update_all, w)
    end
  end

  defp extract_lookup_keys(:process_not_nil, query, params) do
    for w <- query.wheres, into: %{} do
      get_eq_clause(w, params)
    end
  end


  defp get_eq_clause(:update_all, %Ecto.Query.BooleanExpr{expr: expr}) do
    {:==, _, [{{:., _, [{:&, _, [_idx]}, field_atom]}, _, _}, val]} = expr
    {Atom.to_string(field_atom), val}
  end

  defp get_eq_clause(%Ecto.Query.BooleanExpr{expr: expr}, params) do
    {:==, _, [left, right]} = expr
    field = left |> get_field |> Atom.to_string
    value = get_value(right, params)
    {field, value}
  end
  defp get_eq_clause(other, _params) do
    error "Query expression not supported in DynamoDB adapter: #{other}"
  end

  defp get_field({{:., _, [{:&, _, [0]}, field]}, _, []}), do: field
  defp get_field(other_clause) do
    error "Unsupported where clause, left hand side: #{other_clause}"
  end

  defp get_value({:^, _, [idx]}, params), do: Enum.at(params, idx)
  defp get_value(other_clause, _params) do
    error "Unsupported where clause, right hand side: #{other_clause}"
  end

  defp error(msg) do
    raise ArgumentError, message: msg
  end
end
