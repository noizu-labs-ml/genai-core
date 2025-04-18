# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Records.Session do
  @moduledoc """
  Records used by for preparing/encoding VNextGenAI.Session
  """

  require Record

  # =============================================================================
  # Session Records
  # =============================================================================

  # ----------------------------
  # stack_entry Record
  # ----------------------------
  Record.defrecord(:stack_entry, item: nil)

  @typedoc """
  Reference to a stack entry.
  """
  @type stack_entry :: record(:stack_entry, item: any)

  # ----------------------------
  # option_entry Record
  # ----------------------------
  Record.defrecord(:option_entry, option: nil)

  @typedoc """
  Reference to an option entry.
  """
  @type option_entry :: record(:option_entry, option: any)

  # ----------------------------
  # setting_entry Record
  # ----------------------------
  Record.defrecord(:setting_entry, setting: nil)

  @typedoc """
  Reference to a setting entry.
  """
  @type setting_entry :: record(:setting_entry, setting: any)

  # ----------------------------
  # tool_entry Record
  # ----------------------------
  Record.defrecord(:tool_entry, tool: nil)

  @typedoc """
  Reference to a tool entry.
  """
  @type tool_entry :: record(:tool_entry, tool: any)

  # ----------------------------
  # model_entry Record
  # ----------------------------
  Record.defrecord(:model_entry, [])

  @typedoc """
  Reference to a model entry.
  """
  @type model_entry :: record(:model_entry, [])

  # ----------------------------
  # model_setting_entry Record
  # ----------------------------
  Record.defrecord(:model_setting_entry, model: nil, setting: nil)

  @typedoc """
  Reference to a model-specific setting entry.
  """
  @type model_setting_entry ::
          record(:model_setting_entry, model: any, setting: any)

  # ----------------------------
  # provider_setting_entry Record
  # ----------------------------
  Record.defrecord(:provider_setting_entry, provider: nil, setting: nil)

  @typedoc """
  Reference to a provider-specific setting entry.
  """
  @type provider_setting_entry ::
          record(:provider_setting_entry, provider: any, setting: any)

  # ----------------------------
  # session_entry Type
  # ----------------------------
  @typedoc """
  Session Dynamic Entry Records
  """
  @type session_entry ::
          stack_entry
          | option_entry
          | setting_entry
          | tool_entry
          | model_entry
          | model_setting_entry
          | provider_setting_entry

  # ----------------------------
  # entry_reference Record
  # ----------------------------
  Record.defrecord(:entry_reference,
    entry: nil,
    expired?: false,
    finger_print: nil,
    inserted_at: nil,
    updated_at: nil
  )

  @typedoc """
  Reference to a session entry with finger print and tracking fields for invalidation tracking.
  """
  @type entry_reference ::
          record(:entry_reference,
            entry: session_entry,
            finger_print: any,
            inserted_at: any,
            updated_at: any
          )

  # ----------------------------
  # selector Record
  # ----------------------------
  # Calculate effective/tentative value for option
  Record.defrecord(:selector,
    id: nil,
    handle: nil,
    for: nil,
    value: nil,
    directive: nil,
    inserted_at: nil,
    updated_at: nil,
    impacts: [],
    references: []
  )

  @typedoc """
  Settings to calculate effective/tentative value for entry.
  """
  @type selector ::
          record(:selector,
            id: any,
            handle: any,
            for: any,
            value: any,
            directive: any,
            inserted_at: any,
            updated_at: any,
            impacts: list(any),
            references: list(any)
          )

  # ----------------------------
  # constraint Record
  # ----------------------------
  # Constraint on allowed option values.
  Record.defrecord(:constraint,
    id: nil,
    handle: nil,
    for: nil,
    value: nil,
    directive: nil,
    inserted_at: nil,
    updated_at: nil,
    impacts: [],
    references: []
  )

  @typedoc """
  Settings to calculate constraints for entry.
  """
  @type constraint ::
          record(:constraint,
            id: any,
            handle: any,
            for: any,
            value: any,
            directive: any,
            inserted_at: any,
            updated_at: any,
            impacts: list(any),
            references: list(any)
          )

  # ----------------------------
  # effective_value Record
  # ----------------------------
  # Constraint computed effective option value with cache tag for invalidation.
  # tracking fields.
  Record.defrecord(:effective_value,
    id: nil,
    handle: nil,
    value: nil,
    finger_print: nil,
    expired?: false,
    inserted_at: nil,
    updated_at: nil
  )

  @typedoc """
  Effective value for entry as of point in graph.
  """
  @type effective_value ::
          record(:effective_value,
            id: any,
            handle: any,
            value: any,
            finger_print: any,
            inserted_at: any,
            updated_at: any
          )

  # ----------------------------
  # tentative_value Record
  # ----------------------------
  # Constraint computed tentative option value with cache tag for invalidation.
  # tracking fields.
  Record.defrecord(:tentative_value,
    id: nil,
    handle: nil,
    value: nil,
    finger_print: nil,
    inserted_at: nil,
    updated_at: nil
  )

  @typedoc """
  Tentative value for entry as of point in graph.
  """
  @type tentative_value ::
          record(:tentative_value,
            id: any,
            handle: any,
            value: any,
            finger_print: any,
            inserted_at: any,
            updated_at: any
          )

  # =============================================================================
  # Session ProcessNodeProtocol Records
  # =============================================================================

  # ----------------------------
  # process_update Record
  # ----------------------------
  # Return list of any fields to update.
  Record.defrecord(:process_update,
    graph_node: nil,
    graph_link: nil,
    graph_container: nil,
    session_state: nil,
    session_runtime: nil
  )

  @typedoc """
  Scope change list.
  """
  @type process_update ::
          record(:process_update,
            graph_node: any,
            graph_link: any,
            graph_container: any,
            session_state: any,
            session_runtime: any
          )

  # ----------------------------
  # scope Record
  # ----------------------------
  # Standard input arg (duplicates node, useful for comparing new to old value.
  Record.defrecord(:scope,
    graph_node: nil,
    graph_link: nil,
    graph_container: nil,
    session_state: nil,
    session_runtime: nil
  )

  @typedoc """
  Scope/context. Node, Graph, State, Runtime, etc.
  """
  @type scope ::
          record(:scope,
            graph_node: any,
            graph_link: any,
            graph_container: any,
            session_state: any,
            session_runtime: any
          )

  # ----------------------------
  # process_next Record
  # ----------------------------
  # Indicates that the node should be processed next.
  Record.defrecord(:process_next, link: nil, update: nil)

  @typedoc """
  Indicate node to process next.
  """
  @type process_next :: record(:process_next, link: any, update: process_update)

  # ----------------------------
  # process_end Record
  # ----------------------------
  # Indicates that processing is complete.
  Record.defrecord(:process_end, exit_on: nil, update: nil)

  @typedoc """
  Indicate no further nodes to process.
  """
  @type process_end :: record(:process_end, exit_on: any, update: process_update)

  # ----------------------------
  # process_yield Record
  # ----------------------------
  # Yield before resuming for external response (or wait on other node completion/global state).
  Record.defrecord(:process_yield, yield_for: nil, update: nil)

  @typedoc """
  Indicate a blocking call/condition must be met before proceeding.
  """
  @type process_yield :: record(:process_yield, yield_for: any, update: process_update)

  # ----------------------------
  # process_error Record
  # ----------------------------
  # Indicates that an error has occurred.
  Record.defrecord(:process_error, error: nil, update: nil)

  @typedoc """
  Indicate error occured while processing node.
  """
  @type process_error :: record(:process_error, error: any, update: process_update)

  #
  #    #------------------
  #    # node protocol definition helpers.
  #    #------------------
  #
  #    # retrieve n records from data_generator for a given data_set.
  #    Record.defrecord(:data_set, [name: nil, records: 1])
  #
  #    # Grab value from global stack
  #    Record.defrecord(:stack, [item: nil, default: nil])
  #    # Grab sub value from global stack
  #    Record.defrecord(:stack_item_value, [item: nil, path: [], default: nil])
  #
  #    # Grab input value
  #    Record.defrecord(:input, [value: nil, default: nil])
  #    # Grab nested item from input value
  #    Record.defrecord(:input_element, [value: nil, path: [], default: nil])
  #
  #    # grab message state entry or nested entry
  #    Record.defrecord(:message, [id: nil, handle: nil])
  #    Record.defrecord(:message_value, [id: nil, path: nil])
  #    Record.defrecord(:message_filter, [filter: nil])
  #    Record.defrecord(:message_filter_value, [filter: nil, path: []])
  #
  #    # grab link state entry or nested entry
  #    Record.defrecord(:link, [id: nil, handle: nil])
  #    Record.defrecord(:link_value, [id: nil, handle: nil, path: []])
  #    Record.defrecord(:link_filter, [filter: nil])
  #    Record.defrecord(:link_filter_value, [filter: nil, path: []])
  #
  #    # Grab Runtime Flag
  #    Record.defrecord(:runtime, [setting: nil])
  #
  #    # grab tool definition
  #    Record.defrecord(:tool, [id: nil, handle: nil, name: nil])
  #    Record.defrecord(:tool_filter, [filter: nil])
  #
  #    # grab directive by id or handle or by impacts lists (or references list)
  #    Record.defrecord(:directive, [id: nil, handle: nil])
  #    Record.defrecord(:directive_by_tag, [in: nil, not_in: nil, only: nil])
  #
  #    Record.defrecord(:directive_by_source, [source: nil])
  #    Record.defrecord(:directive_by_impacts, [impacts: nil])
  #    Record.defrecord(:directive_by_impacts_all, [impacts_all: nil])
  #    Record.defrecord(:directive_by_references, [references_any: nil])
  #    Record.defrecord(:directive_by_references_all, [references_all: nil])
  #
  #    # grab directive by id or handle
  #    Record.defrecord(:setting, [name: nil])
  #    Record.defrecord(:safety_setting, [name: nil])
  #    Record.defrecord(:model_setting, [name: nil])
  #    Record.defrecord(:provider_setting, [provider: nil, name: nil])
  #
  #
  #
  #    # Force invalidation / Ignore - special methods
  #    Record.defrecord(:ttl, [expiry: 300])
  #    # Values will be converted to the lowest specified unit. So setting day 5, hour 4 will invalidate every 5 * 24 + 4 hours.
  #    Record.defrecord(:time_bucket, [years: nil, months: nil, days: nil, hours: nil, seconds: nil])
  #    def dynmaic_node(), do: {:__genai__, :dynamic}
  #    def finger_print(value, as \\ :auto), do: {{:__genai__, :finger_print, as}, value}
  #    def no_finger_print(value), do: {{:__genai__, :no_finger_print}, value}
end
