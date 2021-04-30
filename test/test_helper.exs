ExUnit.start()

Preview.Fake.start()
File.rm_rf!(Application.get_env(:preview, :tmp_dir))
Mox.defmock(Preview.HexpmMock, for: Preview.Hexpm)
Mox.defmock(Preview.HexMock, for: Preview.Hex)
