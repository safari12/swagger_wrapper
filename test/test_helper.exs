Code.require_file("test/http_behaviour.ex")
Code.require_file("test/test_wrapper.ex")

Mox.Server.start_link([])
Mox.defmock(Http.Mock, for: Http.Behaviour)

ExUnit.start()
