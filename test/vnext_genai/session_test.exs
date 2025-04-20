defmodule GenAI.VNext.SessionTest do
  use ExUnit.Case,
      async: true
  @moduletag :wip2

  describe "GenAI.Thread.Session Acceptance Tests" do

    test "Setup Session Thread" do

      context = Noizu.Context.system()
      model = GenAI.Support.TestProvider.Models.model_one()

      thread = GenAI.chat(:session)
               |> GenAI.with_model(model)
               |> GenAI.with_setting(:temperature, 0.5)
               |> GenAI.with_message(GenAI.Message.system("System Prompt"))
               |> GenAI.with_message(GenAI.Message.user("Hello"))
      assert thread.__struct__ == GenAI.Thread.Session

      {:ok, {response, thread}} = thread
                                  |> GenAI.run(context)
      assert response == [:get_model, :get_provider, :call_provider_execute]


    end # End Setup Test


  end # End Acceptance Tests
end