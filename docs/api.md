# API Documentation
- **Unless explicitly specified, all API calls must be done under `/api` and all request body and response are in JSON format**
- `List`'s in urlencoded means that you should set the key as many times as there are values, like `?a=b&a=c&a=d`
- `boolean` in urlencoded and multipart/form-data means either `1/0`, `yes/no` or `true/false`
- `CSV` in multipart/form-data means a list, with coma delimiters and double quotes for string values, double quotes in content are doubled

***NOTICE: Only endpoints marked with [x] are currently implemented. This will likely change in the future.***

## Authentication
- **Unless explicitly specified, al API calls must be authenticated**
- Authentication can be either
	- A query parameter called `key`
	- A header called `API-Key`
	- A cookie called `key`
- An invalid or expired API Key will always result in an error, even on public endpoints
- API Keys are subject to a permission system
	- `read` allows read permissions for the entire API
	- `write` allows write permissions for the entire API, and includes `read`
	- `upload` allows the use of the `PUT` and `POST` methods on the `/upload` endpoint
	- `api` allows unrestricted access to the entire API
- API Keys can be obtained through the `/login` endpoint
- An API Key should be considered opaque
- Authentication errors will return a result with ok=false, autherror=true, keyloc describing how the API key was passed (if available) and err describing the error

## API Endpoints
### `GET` `/version` [x]
**Public**

- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Version?`

### `GET` `/status` [x]
**Public**

- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Status?`

### `POST` `/login` [x]
**Public**  
**Encoding: `multipart/form-data`|`application/json`|`application/x-www-form-urlencoded`**  
Logs in and allows API access, given that the password and parameters are valid.  
Attempting to login with the same name as an existing API Key will revoke the corresponding key.

- **Body**:
	- `password`: `string`
	- `name`: `string`
	- `permissions`: `List<string>` (if urlencoded or json) `CSV<string>` (if form-data)
	- `expires`: `int:timestamp?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Key?`

### `GET` `/keys` [x]
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[PartialKey]?`

### `DELETE` `/keys/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `POST` `/changepassword` [x]
**Encoding: `multipart/form-data`|`application/json`|`application/x-www-form-urlencoded`** 
- **Body**:
	- `oldpassword`: `string`
	- `newpassword`: `string`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `GET` `/prefetch/:id`
- **Params**:
	- `id`: `int`
- **Query**:
	- `columns`: `List<string>`
	- `offset`: `int?`
	- `limit`: `int?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[object]`

### `DELETE` `/prefetch/:id`
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `GET` `/prefetch/:id/info`
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `PrefetchInfo?`

### `PUT` `/upload` [x] (doesn't check for collisions proprely)
- **Body**: File, raw
- **Query**:
	- `tags`: `List<int|string>`
	- `albums`: `List<int|string>`
	- `name`: `string?`
	- `description`: `string?`
	- `nsfw`: `boolean`
	- `format`: `string|int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `DirectImage?`

### `POST` `/upload`
**Encoding: `multipart/form-data`**

- **Body**:
	- `tags`: `CSV<int|string>`
	- `albums`: `CSV<int|string>`
	- `name`: `string?`
	- `description`: `string?`
	- `nsfw`: `boolean`
	- `format`: `string|int`
	- `file`: `File`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `DirectImage?`

### `GET` `/images` [x]
- **Query**:
	- `yestags`: `List<int|string>` default `[]`
	- `notags`: `List<int|string>` default `[]`
	- `anytags`: `List<int|string>` default `[]`
	- `album`: `int?`
	- `q`: `string?`
	- `name`: `string?`
	- `nsfw`: `boolean|'any'` default `any`
	- `kind`: `'image'|'video'|'any'` default `'any'`
	- `before`: `int:timestamp?`
	- `after`: `int:timestamp?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[PartialImage]?`

### `GET` `/images/prefetch`
- **Query**:
	- `yestags`: `List<int|string>` default `[]`
	- `notags`: `List<int|string>` default `[]`
	- `anytags`: `List<int|string>` default `[]`
	- `album`: `int?`
	- `q`: `string?`
	- `name`: `string?`
	- `nsfw`: `boolean|'any'` default `any`
	- `kind`: `'image'|'video'|'any'` default `'any'`
	- `before`: `int:timestamp?`
	- `after`: `int:timestamp?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `PrefetchInfo?`

### `GET` `/images/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Image?`

### `PATCH` `/images/:id` [x]
- **Params**:
	- `id`: `int`
- **Body**:
	- `name`: `string?`
	- `description`: `string?`
	- `nsfw`: `boolean`
	- `tags`: `array[int|string]`
	- `albums`: `array[int|string]`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `DirectImage?`

### `DELETE` `/images/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `GET` `/images/list` *deprecated*
- **Query**:
	- `id`: `array[int]` limit `50`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[Image]?`

### `GET` `/images/:id/raw` [x]
- **Params**:
	- `id`: `int`
- **Response**: File, raw

### `GET` `/images/public/:filename` [x]
**Public**  
Note that while this endpoint is public, knowledge of both the filename (ID and extension) and the hash of the image is required.  
This endpoint is essentially a share link for an image, since it can't be guessed nor (reasonably) bruteforced.

- **Params**:
	- `filename`: `string`
- **Query**
	- `hash`: `string`
- **Response**: File, raw

### `GET` `/albums` [x]
- **Query**:
	- `yestags`: `List<int|string>` default `[]`
	- `notags`: `List<int|string>` default `[]`
	- `anytags`: `List<int|string>` default `[]`
	- `q`: `string?`
	- `name`: `string?`
	- `nsfw`: `boolean|'any'` default `'any'`
	- `minimagecount`: `int?`
	- `maximagecount`: `int?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[PartialAlbum]?`

### `PUT` `/albums` [x]
- **Body**:
	- `name`: `string`
	- `description`: `string?`
	- `nsfw`: `boolean`
	- `tags`: `array[int|string]`
	- `images`: `array[int]`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `DirectAlbum?`

### `GET` `/albums/prefetch`
- **Query**:
	- `yestags`: `List<int|string>` default `[]`
	- `notags`: `List<int|string>` default `[]`
	- `anytags`: `List<int|string>` default `[]`
	- `q`: `string?`
	- `name`: `string?`
	- `nsfw`: `boolean|'any'` default `'any'`
	- `minimagecount`: `int?`
	- `maximagecount`: `int?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `PrefetchInfo?`

### `GET` `/albums/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Album?`

### `PATCH` `/albums/:id` [x]
- **Params**:
	- `id`: `int`
- **Body**:
	- `name`: `string`
	- `description`: `string?`
	- `nsfw`: `boolean`
	- `tags`: `array[int|string]`
	- `images`: `array[int]`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `DirectAlbum?`

### `DELETE` `/albums/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `GET` `/albums/list` *deprecated*
- **Query**:
	- `id`: `array[int]` limit `50`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[Album]?`

### `GET` `/tags` [x]
- **Query**:
	- `q`: `string?`
	- `name`: `string?`
	- `color`: `string:hex?`
	- `nsfw`: `boolean|'any'` default `'any'`
	- `minimagecount`: `int?`
	- `maximagecount`: `int?`
	- `minalbumcount`: `int?`
	- `maxalbumcount`: `int?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[PartialTag]?`

### `PUT` `/tags` [x]
- **Body**:
	- `name`: `string`
	- `description`: `string?`
	- `color`: `string:hex:6`
	- `nsfw`: `boolean`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Tag?`

### `GET` `/tags/prefetch`
- **Query**:
	- `q`: `string?`
	- `name`: `string?`
	- `color`: `string:hex?`
	- `nsfw`: `boolean|'any'` default `'any'`
	- `minimagecount`: `int?`
	- `maximagecount`: `int?`
	- `minalbumcount`: `int?`
	- `maxalbumcount`: `int?`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `PrefetchInfo?`

### `GET` `/tags/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Tag?`

### `PATCH` `/tags/:id` [x]
- **Params**:
	- `id`: `int`
- **Body**:
	- `description`: `string?`
	- `color`: `string:hex:6`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Tag?`

### `DELETE` `/tags/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `GET` `/tags/list` [x] *deprecated*
- **Query**:
	- `id`: `array[int]` limit `50`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[Tag]?`

### `GET` `/formats` [x]
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[Format]?`

### `PUT` `/formats` [x]
- **Body**:
	- `name`: `string`
	- `video`: `boolean`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Format?`

### `GET` `/formats/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `Format?`

### `DELETE` `/formats/:id` [x]
- **Params**:
	- `id`: `int`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`

### `GET` `/formats/list` [x] *deprecated*
- **Query**:
	- `id`: `array[int]` limit `50`
- **Response**:
	- `ok`: `boolean`
	- `err`: `string?`
	- `res`: `array[Format]?`

## Resources
### `Version`
- `appname`: `string`
- `version`: `string`
- `commit`: `string:hex?`
- `branch`: `string?`

### `Status`
- `imagecount`: `int`
- `albumcount`: `int`
- `tagcount`: `int`
- `formatcount`: `int`

### `Key`
- `id`: `int`
- `name`: `string`
- `key`: `string:opaque`
- `expires`: `int:timestamp?`
- `permissions`: `array[string]`

### `PartialKey`
- `id`: `int`
- `name`: `string`
- `expires`: `int:timestamp?`
- `permissions`: `array[string]`

### `PrefetchInfo`
- `id`: `int`
- `type`: `string`
- `expires`:`int:timestamp`
- `columns`: `array[string]`

### `Image`
- `id`: `int`
- `name`: `string?`
- `description`: `string?`
- `nsfw`: `boolean`
- `width`: `int`
- `height`: `int`
- `format`: `Format`
- `adddate`: `int:timestamp`
- `checksum`: `string:hex`
- `albums`: `array[SubPartialAlbum]`
- `tags`: `array[PartialTag]`

### `DirectImage`
- `id`: `int`
- `name`: `string?`
- `description`: `string?`
- `nsfw`: `boolean`
- `width`: `int`
- `height`: `int`
- `format`: `Format`
- `adddate`: `int:timestamp`
- `checksum`: `string:hex`
- `albums`: `array[int]`
- `tags`: `array[int]`

### `PartialImage`
- `id`: `int`
- `name`: `string?`
- `nsfw`: `boolean`
- `width`: `int`
- `height`: `int`
- `format`: `Format`
- `adddate`: `int:timestamp`
- `checksum`: `string:hex`
- `albums`: `array[SubPartialAlbum]` limit 10
- `tags`: `array[PartialTag]` limit 10

### `SupPartialImage`
- `id`: `int`
- `name`: `string?`
- `nsfw`: `boolean`
- `width`: `int`
- `height`: `int`
- `format`: `Format`
- `adddate`: `int:timestamp`
- `checksum`: `string:hex`

### `Album`
- `id`: `int`
- `name`: `string`
- `description`: `string?`
- `nsfw`: `boolean`
- `images`: `array[SubPartialImage]`
- `tags`: `array[PartialTag]`
- `imagecount`:`int`

### `DirectAlbum`
- `id`: `int`
- `name`: `string`
- `description`: `string?`
- `nsfw`: `boolean`
- `images`: `array[int]`
- `tags`: `array[int]`
- `imagecount`:`int`

### `PartialAlbum`
- `id`: `int`
- `name`: `string`
- `nsfw`: `boolean`
- `images`: `array[SubPartialImage]` limit 10
- `tags`: `array[PartialTag]` limit 10
- `imagecount`:`int`

### `SubPartialAlbum`
- `id`: `int`
- `name`: `string`
- `nsfw`: `boolean`

### `Tag`
- `id`: `int`
- `name`: `string`
- `description`: `string?`
- `color`: `string:rgb`
- `nsfw`: `boolean`
- `imagecount`: `int`
- `albumcount`: `int`

### `PartialTag`
- `id`: `int`
- `name`: `string`
- `color`: `string:rgb`
- `nsfw`: `boolean`
- `imagecount`: `int`
- `albumcount`: `int`

### `Format`
- `id`: `int`
- `name`: `string`
- `video`: `boolean`
