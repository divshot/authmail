# AuthMail

AuthMail is an open source SaaS microservice that provides password-free authentication
for developers. It works by emailing users a short-lived login link that, when clicked,
delivers a securely signed verification.

For more information about how AuthMail works as a product, see [the documentation](https://authmail.co/docs)
on the hosted site.

## Local Development

First, you will need to have MongoDB and Redis installed on your development machine.
Next, you must create a `.env` file and populate the following variables:

```
ORIGIN=http://localhost:3000       # the Origin from which AuthMail will be served
SECRET=abc123                      # a random secret (use script/secret to generate)
```

Next, just install dependencies and run the server!

```
bundle install
rackup -p 3000
```

## Usage Suggestions

This service and all its code are released under the permissive MIT license. We
offer the source in good faith so that you may tinker and contribute to your
heart's content.

If you decide to run your own AuthMail server, we ask that you do it only for
single-tenant (i.e. your own application) purposes. Spirit of collaboration and
all that.

## License (MIT)

Copyright (c) 2014 Divshot, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.