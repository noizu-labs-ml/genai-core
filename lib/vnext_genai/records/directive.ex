# ===============================================================================
# Copyright (c) 2025, Noizu Labs, Inc.
# ===============================================================================
defmodule GenAI.Records.Directive do
  @moduledoc """
  Records used by for directive processing.
  """
  
  require Record
  
  
  #=============================================================================
  # entry value records
  #=============================================================================
  
  @typedoc """
  Concrete Entry Value.
  """
  @type concrete_value :: record(:concrete_value, value: any)
  Record.defrecord(:concrete_value, value: nil)
  
  #=============================================================================
  # entry selector records
  #=============================================================================

  # ----------------------------
  # message_entry Record
  # ----------------------------
  @typedoc """
  Reference to a message list.
  """
  @type message_entry :: record(:message_entry, msg: any)
  Record.defrecord(:message_entry, msg: nil)

  # ----------------------------
  # monitor_entry Record
  # ----------------------------
  @typedoc """
  Reference to a monitor entry.
  """
  @type monitor_entry :: record(:monitor_entry, monitor: any)
  Record.defrecord(:monitor_entry, monitor: nil)
  
  # ----------------------------
  # data_generator_entry Record
  # ----------------------------
  @typedoc """
  Reference to a data generator entry.
  """
  @type data_generator_entry :: record(:data_generator_entry, generator: any)
  Record.defrecord(:data_generator_entry, generator: nil)
  
  
  # ----------------------------
  # stack_entry Record
  # ----------------------------
  @typedoc """
  Reference to a stack entry.
  """
  @type stack_entry :: record(:stack_entry, element: any)
  Record.defrecord(:stack_entry, element: nil)
  
  
  # ----------------------------
  # option_entry Record
  # ----------------------------
  @typedoc """
  Reference to an option entry.
  """
  @type option_entry :: record(:option_entry, option: any)
  Record.defrecord(:option_entry, option: nil)
  
  
  # ----------------------------
  # setting_entry Record
  # ----------------------------
  @typedoc """
  Reference to a setting entry.
  """
  @type setting_entry :: record(:setting_entry, setting: any)
  Record.defrecord(:setting_entry, setting: nil)
  
  
  # ----------------------------
  # tool_entry Record
  # ----------------------------
  @typedoc """
  Reference to a tool entry.
  """
  @type tool_entry :: record(:tool_entry, tool: any)
  Record.defrecord(:tool_entry, tool: nil)
  
  # ----------------------------
  # model_entry Record
  # ----------------------------
  @typedoc """
  Reference to a model entry.
  """
  @type model_entry :: record(:model_entry, [])
  Record.defrecord(:model_entry, [])
  
  
  # ----------------------------
  # model_setting_entry Record
  # ----------------------------
  @typedoc """
  Reference to a model-specific setting entry.
  """
  @type model_setting_entry ::
          record(:model_setting_entry, model: any, setting: any)
  Record.defrecord(:model_setting_entry, model: nil, setting: nil)
  
  
  # ----------------------------
  # provider_setting_entry Record
  # ----------------------------
  
  @typedoc """
  Reference to a provider-specific setting entry.
  """
  @type provider_setting_entry ::
          record(:provider_setting_entry, provider: any, setting: any)
  Record.defrecord(:provider_setting_entry, provider: nil, setting: nil)
  
  
  # ----------------------------
  # safety_setting_entry Record
  # ----------------------------
  
  @typedoc """
  Reference to a safety setting entry.
  """
  @type safety_setting_entry ::
          record(:safety_setting_entry, category: any)
  Record.defrecord(:safety_setting_entry, category: nil)



end