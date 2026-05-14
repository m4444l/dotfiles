---
name: avo
description: Guidance for working with the Ruby on Rails Avo CMS. Use when creating or updating Avo resources, dashboards, actions, filters, or any other Avo-related functionality.
---

# Avo

## Guidelines

- Full LLM docs for Avo are available at `https://docs.avohq.io/3.0/llms-full.txt`. Only fetch this if the instructions in this skill and existing Avo code in the codebase are not sufficient to complete the task.

## Adding Resources

Avo resources go in `app/avo/resources`.
Use this as the baseline structure for a new Avo resource:

```ruby
# frozen_string_literal: true

class Avo::Resources::NewResource < Avo::BaseResource
  def fields
    field :id
    [belongs_to and attribute fields here]
    tasks_field
    timestamp_fields
    [has_one association fields here]
    [has_many association fields here]
  end

  _baseline_finalize
end
```

Always add a matching controller in `app/controllers/avo` as well:

```ruby
# frozen_string_literal: true

class Avo::NewResourcesController < Avo::ResourcesController
end
```

## Fields

Fields can be added without specifying a type via the `:as` parameter:

```ruby
field :name
field :pdf_file
field :processed_at
```

If no `:as` parameter is present, the type and default attributes are determined automatically. See `Baseline::ActsAsAvoResource#field` in Baseline for details.
