# Preview

Webbased display for the contents of a Hex release.

## Contributing

### Setup

1. Run `mix setup` to install Hex and NPM dependencies
2. Run `mix test`
3. Run `mix phx.server` and visit [http://localhost:4005/](http://localhost:4005/)

### Test routes
After running `mix setup`, two packages will be available for testing locally.

1. [Decimal 2.0.0](http://localhost:4005/preview/decimal/2.0.0)
2. [Ecto 0.2.0](http://localhost:4005/preview/ecto/0.2.0)

### Updating dependencies

If Hex or NPM dependencies are outdated run `mix setup` again.

## License

    Copyright 2020 Six Colors AB

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
