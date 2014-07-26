[![Build Status](https://travis-ci.org/tandrewnichols/tinder-cli.png)](https://travis-ci.org/tandrewnichols/tinder-cli) [![downloads](http://img.shields.io/npm/dm/tinder-cli.svg)](https://npmjs.org/package/tinder-cli) [![npm](http://img.shields.io/npm/v/tinder-cli.svg)](https://npmjs.org/package/tinder-cli)

# Tinder

A command line tool for quickly creating a node.js repository from an existing template.

**NOTE: THIS IS _NOT_ RELATED TO THE TINDER DATING SERVICE**

## Installation

`npm install tinder-cli -g`

## What is this thing?

Doing the same setup, installation, initialization, etc. for every repository is a bad idea. For me, it typically prevents me from actually doing the work I want to do because I don't want to do the work necessary to get started . . . again. If you've done much development, you probably find that you use a lot of the same patterns and third-party modules in every module/app you write. It's time to automate that setup so you can get back to producing cool code that changes the world.

Tinder is most definitely in its infancy. There are a lot of ideas that didn't make it into this initial release because I wanted to get something out there _quick_. But I also plan to amend that quickly because, frankly, I'm planning to use this too, and I want all those cool features.

Right now, tinder can setup a new repository from an existing template, make an initial commit, even create a new github repository for you. It uses underscore templating to allow for flexible templates. But, honestly, filling in those variables is one of the current pain points, so that's likely to be one of the first things that changes.

## Usage

Create a new repository named "myApp" based on the template "some-template":

`tinder mk myApp some-template "Description of the project"`

Both the template name and the description are optional and can be passed via options instead.

Options:

```
  -u --user <username>:[password]   Github username
  -p --pass <password>              Github password
  -d --description <description>    Description of the project
  -t --template <name>              Name of the template to base the project on
  -v --vars <json>                  Additional variables for underscore templating
  -i --interpolate <pattern>        Underscore interpolation pattern (in case you're not into erb style)
  -e --evaluate <pattern>           Underscore evaluate pattern
  -E --escape <pattern>             Underscore escape pattern
  -c --no-clean                     Do not clean up if something goes wrong. I have no idea why you would want to do this, but it seemed better to give you the choice.
  -P --private                      Create a private github repo
  -w --no-wiki                      Don't create a wiki
  -I --no-issues                    Don't create an issues page
```

## What _exactly_ does this do?

1. Build a github url based on the template and your username.
2. Clone the template into a temporary directory.
3. Copy the template directory of that clone into a directory with the name of your project.
4. Find and replace interpolation recursively in the new project.
5. Create a git repo.
6. Initialize a local git repo.
7. Create a remote that points to the new repo.
8. Add, commit, and push the new repo up to github.
9. Cleanup the temporary directory.

## Example

Imagine a template (let's call it Steve) with this directory structure:

README.md
template
  README.md
  package.json

When you run tinder using this template, your new repository will have a README.md and a package.json (the contents of the template directory).

If README.md looked like this:

```
# <%= repoName %>

<%= description %>
```

and you created the repo like this:

`tinder mk Bob Steve "The best app in the world"`

the resulting README.md in your Steve repo would look like this:

```
# Steve

The best app in the world
```

So what about more complicated things, like using some common 3rd party modules? Underscore templating is pretty flexible. If you need a crash course, it's best to check out [underscore](http://underscorejs.org/#template) itself. But it might look something like this (in package.json):

```
{
  "dependencies": {
    <% _.chain(dependencies).keys().each(function(dep, i, arr) { %>
    "<%= dep %>": "<%= dependencies[dep] %>"<% if(i < arr.length - 1) { %>,<% } %>
    <% }); %>
  }
}
```

## What are some of the ideas you didn't get to?

1. `--vars` is hard to use. The interpolation process should be interactive, prompting you for values as it finds interpolation variables it doesn't know about.
2. `npm init` can do a lot of easy setup for you. I'm planning to wrap that.
3. There needs to be a `config` command that let's you register (e.g.) templates, your github info, patterns, etc. so that you don't have to retype the same options.
4. Interpolate, evaluate, and escape should accept patterns or names of common patterns (e.g. mustache)
5. Asking for a password in plain text is bad.
6. This basically only works with github repositories you've pushed up, but it would be nice to make tinder templates publishable on npm and consumable as part of the `npm install` process.
7. For development, there needs to be a dry-run and/or debug flag because going back to Github to remove test repositories all the time is a pain.

## Contributing

Please do. You can get started by cloning this repo and running `npm install`, `npm link`, and `npm test`.
