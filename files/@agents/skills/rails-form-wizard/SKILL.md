---
name: rails-form-wizard
description: Guidance for implementing multi-step wizard forms using Baseline::Wizardify and Baseline::Wizardable. Use when creating or modifying wizard forms, multi-step forms, or when user says "wizard", "multi-step form", or "form steps".
---

# Rails Form Wizard

## Overview

This skill provides guidance for implementing multi-step wizard forms. Wizards are built using the `Baseline::Wizardify` controller concern and `Baseline::Wizardable` model concern from the Baseline gem.

## Architecture

### Core Components

The wizard system consists of three main layers:

1. **Controller Concern** (`Baseline::Wizardify`) - Handles step navigation, form submission, and wizard lifecycle
2. **Model Concern** (`Baseline::Wizardable`) - Manages step state, validation per step, and completion tracking
3. **View Components** - Step-specific templates and shared form actions

### How Wizards Work

1. User visits the wizard index action → redirected to first (or last unfinished) step
2. Each step is a separate action with its own view template
3. Form submission triggers `update` action → saves current step → redirects to next step
4. After the last step, `finished_at` is set and user is redirected to `success` action
5. The `form_step` column tracks which step the user is currently on

## File Structure

For a new wizard called `ThingRequests`, you need:

```
app/
├── controllers/
│   └── {namespace}/
│       └── thing_requests_controller.rb    # Controller with Wizardify
├── models/
│   └── things/
│       └── thing_request.rb                # Model with Wizardable
├── views/
│   └── {namespace}/
│       └── thing_requests/
│           ├── _form_step.html.haml        # Shared form wrapper
│           ├── step_one.html.haml          # First step view
│           ├── step_two.html.haml          # Second step view
│           ├── step_three.html.haml        # Third step view
│           └── success.html.haml           # Completion page
├── javascript/
│   └── controllers/
│       └── {namespace}/
│           └── thing_requests_show_controller.js  # Optional Stimulus controller
config/
├── routes/
│   └── {namespace}.rb                      # Route definition
└── locales/
    └── {namespace}.{de,en}.yml             # I18n translations
db/
└── migrate/
    └── YYYYMMDDHHMMSS_create_thing_requests.rb  # Migration
```

## Step-by-Step Implementation

### 1. Create the Database Migration

The model needs two required columns for wizard functionality:

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_thing_requests.rb
class CreateThingRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :thing_requests do |t|
      # Required for wizard functionality
      t.string :form_step                    # Tracks current step
      t.datetime :finished_at                # Marks completion

      # Your domain-specific columns
      t.string :name
      t.text :description
      t.integer :category
      # ... other fields for your wizard

      # Optional: associate with user/owner
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
```

### 2. Create the Model

Include `Baseline::Wizardable` and `HasTimestamps[:finished_at]`, then define `form_step_params`:

```ruby
# app/models/things/thing_request.rb
class ThingRequest < ApplicationRecord
  include Baseline::Wizardable,
          HasTimestamps[:finished_at]

  # Associations
  belongs_to :user, optional: true

  # Step-specific validations using reached_form_step?
  validates :name, presence: { if: -> { reached_form_step?(:details) } }
  validates :category, presence: { if: -> { reached_form_step?(:category) } }
  validates :description, presence: { if: -> { reached_form_step?(:confirmation) } }

  # Define steps and their permitted params
  # Keys define step order and names, values define permitted params
  def form_step_params
    {
      category:     :category,                           # Single attribute
      details:      %i[name email phone],                # Array of attributes
      options:      { option_ids: [] },                  # Array param (for checkboxes)
      confirmation: :description,                        # Final step
      nested:       { items_attributes: {} }             # Nested attributes
    }
  end

  def to_s = "Thing request from #{name}"

  _baseline_finalize
end
```

#### Key Points About `form_step_params`:

- **Keys** are step names (as symbols) - they define the order of steps
- **Values** are permitted params for that step - can be:
  - A single symbol: `:name`
  - An array of symbols: `%i[name email phone]`
  - A hash for array/nested params: `{ ids: [] }` or `{ items_attributes: {} }`
  - A hash combining both: `[:name, :email, { ids: [] }]`
- Steps can be **conditional** by returning `nil` (step is skipped):

```ruby
def form_step_params
  {
    primer:     [],                                    # Empty array = no params but step exists
    employee:   (:employee_id if needs_employee?),    # Conditional step
    details:    %i[name description],
    finish:     :terms_accepted
  }.compact  # Remove nil values to skip conditional steps
end
```

### 3. Create the Controller

Include `Baseline::Wizardify` and implement the required methods:

```ruby
# app/controllers/{namespace}/thing_requests_controller.rb
module YourNamespace
  class ThingRequestsController < BaseController
    # Optional: allow unauthenticated access
    # allow_unauthenticated_access

    # Load or initialize the wizard resource
    before_action do
      @thing_request = Current.user
        .thing_requests
        .unfinished
        .first_or_initialize
    end

    # Include the wizard concern AFTER the before_action that sets the resource
    include Baseline::Wizardify

    # Optional: hook called before saving
    def before_wizard_resource_update
      # Set computed attributes, normalize data, etc.
      @thing_request.locale = I18n.locale
    end

    # Optional: hook called after saving (but before redirect)
    def after_wizard_resource_update
      # Side effects after each step saves
    end

    private

      # REQUIRED: Return the wizard resource instance
      def wizard_resource = @thing_request

      # Optional: hook called before finishing the wizard
      def before_finish_wizard
        # Create associated records, set final values
        @thing_request.completed_by = Current.user
      end

      # Optional: hook called after finishing the wizard
      def after_finish_wizard
        # Send notifications, create tasks, redirect logic
        ThingRequestMailer.confirmation(@thing_request).deliver_later
        Tasks::Create.call(
          taskable: @thing_request,
          title:    "Handle new thing request",
          priority: :high
        )
      end

      # Optional: customize page title interpolation
      def page_title_attributes
        { name: @thing_request.name }
      end

      # Optional: override finish redirect path
      # def finish_wizard_path
      #   { action: :success }  # Default
      # end

      # Optional: allow editing after completion
      # def allow_edit_finished
      #   false  # Default
      # end

      _baseline_finalize
  end
end
```

### 4. Create the Routes

Add wizard routes with `index`, `show`, `update` actions and a `success` collection route:

```ruby
# config/routes/{namespace}.rb
constraints URLManager.route_constraints(:your_namespace) do
  namespace :your_namespace, path: "" do
    # ... other routes

    # Basic wizard routes
    resources :thing_requests, only: %i[index show update], path: "request" do
      collection do
        get :success
      end
    end

    # Nested wizard (under a parent resource)
    resources :things, only: %i[index show] do
      resources :thing_requests, only: %i[index show update], path: "apply" do
        collection do
          get :success
        end
      end
    end

    # With locale scope
    scope "(:locale)" do
      resources :thing_requests, only: %i[index show update] do
        collection do
          get :success
        end
      end
    end
  end
end
```

### 5. Create the Shared Form Partial

This partial wraps each step's form and includes navigation:

```haml
-# app/views/{namespace}/thing_requests/_form_step.html.haml
-# frozen_string_literal: true
-# locals: ()

= form_with model: @thing_request, url: wizard_path, method: :patch, class: "thing-request-form", data: turbo_data do |form|
  = yield form
  = component :wizard_actions, form:
```

The `wizard_actions` component provides:
- Back button (links to previous step)
- Progress indicator ("Step 2/4")
- Next/Finish button

#### Customization Options for wizard_actions:

```haml
= component :wizard_actions, form:,
  cancel_url: some_path,              # Show cancel instead of back on first step
  show_current_step: true,            # Show "Step X/Y" indicator
  step_label: t(:question),           # Custom label (default: "Step")
  button_color: "primary"             # Bootstrap button color
```

### 6. Create Step Views

Each step gets its own view file named after the step key in `form_step_params`:

```haml
-# app/views/{namespace}/thing_requests/category.html.haml
-# frozen_string_literal: true

= render "{namespace}/thing_requests/form_step" do |form|
  %h2= page_title

  .mb-4
    = form.label :category, class: "form-label"
    = form.select :category,
      ThingRequest.categories.keys.map { [t(_1, scope: action_i18n_scope + [:categories]), _1] },
      {},
      class: "form-select"
```

```haml
-# app/views/{namespace}/thing_requests/details.html.haml
-# frozen_string_literal: true

= render "{namespace}/thing_requests/form_step" do |form|
  %h2.mb-4= page_title

  .mb-3
    = form.label :name, class: "form-label"
    = form.text_field :name, class: "form-control", required: true

  .mb-3
    = form.label :email, class: "form-label"
    = form.email_field :email, class: "form-control", required: true

  .mb-3
    = form.label :phone, t(:label, scope: action_i18n_scope + [:phone]), class: "form-label"
    = form.text_field :phone, class: "form-control"
```

```haml
-# app/views/{namespace}/thing_requests/confirmation.html.haml
-# frozen_string_literal: true

= render "{namespace}/thing_requests/form_step" do |form|
  %h2= page_title

  = md_to_html t(:intro, scope: action_i18n_scope)

  .mb-4
    = form.label :description, class: "form-label"
    = form.text_area :description, class: "form-control", rows: 5
```

### 7. Create the Success View

```haml
-# app/views/{namespace}/thing_requests/success.html.haml
-# frozen_string_literal: true

%section.text-center.mt-5
  %h2= page_title

  = md_to_html t(:text, scope: action_i18n_scope)

  = link_to [:your_namespace, :root], class: "btn btn-primary mt-4" do
    = t(:continue, scope: action_i18n_scope)
    = component :icon, :forward, style: :solid
```

### 8. Add I18n Translations

```yaml
# config/locales/{namespace}.de.yml
de:
  your_namespace:
    thing_requests:
      show:
        category:
          title: Wähle eine Kategorie
          categories:
            option_a: Option A
            option_b: Option B

        details:
          title: Deine Kontaktdaten
          phone:
            label: Telefonnummer (optional)

        confirmation:
          title: Bestätigung
          intro: |-
            Bitte überprüfe deine Angaben und beschreibe dein Anliegen.

      success:
        title: Vielen Dank!
        text: |-
          Wir haben deine Anfrage erhalten und melden uns bald bei dir.
        continue: Zurück zur Startseite
```

## Helper Methods Available in Views

The `Wizardify` concern provides these helper methods:

| Method | Description |
|--------|-------------|
| `wizard_resource` | The current wizard model instance |
| `wizard_path(step = nil)` | URL for a specific step |
| `current_step` | Current step name (string) |
| `steps` | Array of all step names |
| `step_number` | Current step number (1-indexed) |
| `step_count` | Total number of steps |
| `step_progress` | Percentage complete (0-100) |
| `first_step?` | Is this the first step? |
| `last_step?` | Is this the last step? |
| `current_step?(step)` | Is the given step the current one? |
| `past_step?(step)` | Has the given step been completed? |
| `future_step?(step)` | Is the given step ahead of current? |
| `previous_step` | Previous step name |
| `next_step` | Next step name |
| `frame_id` | Turbo frame ID (`:wizard`) |
| `wizard_cancel_url` | Cancel URL (nil by default) |

## Advanced Patterns

### Conditional Steps

Skip steps based on conditions by using `nil` values in `form_step_params`:

```ruby
def form_step_params
  {
    basics:     %i[name email],
    company:    (company_params if needs_company?),  # Skip if nil
    details:    %i[description],
    finish:     :terms
  }.compact
end

def needs_company?
  user.company.blank?
end
```

### Dynamic Params per Step

```ruby
def form_step_params
  {
    skills: ({ skill_ids: [] } if @job.skills.any?),
    profile: {
      user_attributes: [
        :id,
        location_attributes: %i[country address]
      ]
    }
  }.compact
end
```

### Custom Step Navigation

Override `wizard_value` to use different view names than step keys:

```ruby
# In controller
def wizard_value(step_name)
  step_name.unless(-> { _1 == Baseline::Wizardify::FINISH_STEP }) do
    # Return different view name based on step
    case step_name
    when 'category' then answer.kind  # Use dynamic view name
    else step_name
    end
  end
end
```

### Pre-populating Data from Previous Submissions

```ruby
before_action do
  @thing_request = find_or_initialize_wizard_resource

  if @thing_request.new_record? && last_request = Current.user.thing_requests.finished.last
    %i[preference1 preference2].each do |attr|
      @thing_request.public_send("#{attr}=", last_request.public_send(attr))
    end
  end
end
```

### Cookie-based Tracking for Unauthenticated Users

```ruby
COOKIE_NAME = :thing_request_id

before_action do
  @thing_request =
    if Current.user
      Current.user.thing_requests.unfinished.first_or_initialize
    else
      cookies[COOKIE_NAME]&.then { ThingRequest.find(_1) } ||
        ThingRequest.new
    end
end

def after_wizard_resource_update
  cookies.permanent[COOKIE_NAME] = @thing_request.id unless Current.user
end

def after_finish_wizard
  cookies.delete(COOKIE_NAME) unless Current.user
end
```

### Adding Custom Stimulus Controllers

For step-specific JavaScript behavior:

```javascript
// app/javascript/controllers/{namespace}/thing_requests_show_controller.js
import ApplicationController from "application_controller"

export default class extends ApplicationController {
  static targets = ["categorySelect", "detailsField"]

  categoryChanged() {
    // React to category selection
    const selected = this.categorySelectTarget.value
    this.detailsFieldTargets.forEach(field => {
      field.required = selected === 'custom'
    })
  }
}
```

Reference in views:

```haml
= render "{namespace}/thing_requests/form_step" do |form|
  .mb-4{ data: action_stimco.target(:categorySelect) }
    = form.select :category, options, {}, data: action_stimco.action(change: :categoryChanged)
```

## Existing Wizard Implementations

Reference these for patterns and examples:

| Wizard | Namespace | Model | Description |
|--------|-----------|-------|-------------|
| Job Requests | `clients` | `JobRequest` | Multi-step job posting wizard |
| Interview Requests | `clients` | `InterviewRequest` | Interview scheduling wizard |
| Candidacy Applications | `freelancers/jobs` | `CandidacyApplication` | Freelancer job application |
| Survey Responses | `freelancers/community` | `SurveyResponse` | Survey completion wizard |

Key files to reference:
- `app/controllers/clients/job_requests_controller.rb` - Cookie-based tracking, client creation
- `app/controllers/freelancers/jobs/candidacy_applications_controller.rb` - Nested resource, complex hooks
- `app/models/jobs/job_request.rb` - Simple form_step_params
- `app/models/candidacies/candidacy_application.rb` - Conditional steps, nested attributes

## Common Pitfalls

1. **Order of `include Baseline::Wizardify`** - Must come AFTER the `before_action` that sets `@wizard_resource`

2. **Missing `form_step` and `finished_at` columns** - Both are required in the database

3. **Validation order** - Use `reached_form_step?(:step_name)` for conditional validations, not `form_step == 'step_name'`

4. **Step name mismatches** - Step keys in `form_step_params` must match view file names exactly

5. **Permitted params format** - Remember array params need `{ ids: [] }` format, nested attributes need `{ attrs: {} }`

6. **Forgetting `.compact`** - When using conditional steps, call `.compact` on the hash to remove nil values

7. **Not calling `_baseline_finalize`** - Required at the end of models and controllers

## Testing Wizards

```ruby
# spec/factories/thing_request_factory.rb
FactoryBot.define do
  factory :thing_request do
    name { FFaker::Name.name }
    category { :option_a }

    trait :finished do
      finished_at { Time.current }
      form_step { nil }
    end

    trait :at_step do
      transient do
        step { :category }
      end
      form_step { step.to_s }
    end
  end
end
```

```ruby
# spec/models/thing_request_spec.rb
RSpec.describe ThingRequest do
  describe "validations" do
    context "at details step" do
      subject { build(:thing_request, :at_step, step: :details) }

      it { is_expected.to validate_presence_of(:name) }
    end

    context "at category step" do
      subject { build(:thing_request, :at_step, step: :category) }

      it { is_expected.not_to validate_presence_of(:name) }
    end
  end

  describe "#form_steps" do
    it "returns step names in order" do
      expect(subject.form_steps).to eq(%w[category details confirmation])
    end
  end
end
```

```ruby
# spec/system/thing_requests_spec.rb
RSpec.describe "Thing Requests Wizard", type: :system do
  let(:user) { create(:user) }

  before { sign_in(user) }

  it "completes the wizard" do
    visit your_namespace_thing_requests_path

    # Step 1: Category
    select "Option A", from: "Category"
    click_button "Next"

    # Step 2: Details
    fill_in "Name", with: "Test Name"
    fill_in "Email", with: "test@example.com"
    click_button "Next"

    # Step 3: Confirmation
    fill_in "Description", with: "Test description"
    click_button "Finish"

    # Success page
    expect(page).to have_content("Vielen Dank!")
    expect(ThingRequest.finished.count).to eq(1)
  end
end
```
