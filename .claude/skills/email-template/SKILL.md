---
name: email-template
description: Scaffold a Magento 2 transactional email for "$ARGUMENTS".
argument-hint: Description of the email (e.g., "trial request confirmation and internal notification")
disable-model-invocation: true
metadata:
  capabilities: [magento]
---

Scaffold a Magento 2 transactional email for "$ARGUMENTS".

Load the `email-patterns` skill for conventions before proceeding. Also **read CLAUDE.md** for the project's vendor namespace, PHP conventions, module inventory, Magento CLI commands, PHP quality commands, and the Reuse Before Reimplementing section (especially dual email and branch routing rules).

## Step 1: Parse the request

Extract from $ARGUMENTS:
- **What triggers the email** (e.g. "trial request submitted", "service enquiry", "order status change")
- **Which module** owns this email (check CLAUDE.md module inventory)
- **Recipients**: who gets the email — customer only, internal only, or both (check CLAUDE.md Reuse rules for the project's dual-email convention)
- **Fields**: what data the email should display — if not specified, ask the user

If the description is ambiguous, ask the user to clarify before proceeding.

## Step 2: Study existing email implementations

Read existing email implementations from CLAUDE.md's Reuse Before Reimplementing table — find the transactional email entries and read at least one full example (model + both templates + `email_templates.xml`) to match conventions.

Key conventions from CLAUDE.md Reuse rules:
- Dual emails per form submission (customer confirmation + internal action-required)
- Branch routing via `InventorySource` lookup
- BCC from admin config
- Template variables passed as `['data' => $input]`
- Enquiry code generation pattern

## Step 3: Show the plan

Before writing any files, present:

```
Module: <Vendor>_<Module>
Emails: 2 (customer confirmation + internal)

Template IDs:
  1. <module>_email_template_customer
  2. <module>_email_template_internal

Template variables:
  - data.field_one — "Field One Label"
  - data.field_two — "Field Two Label"
  - ...

Files to create/modify:
  - etc/email_templates.xml (create|modify)
  - view/frontend/email/<name>_customer.html (create)
  - view/frontend/email/<name>_internal.html (create)
  - Model/<Name>.php (create|modify) — add send methods
  - Api/<Name>Interface.php (create|modify) — add send method signature
  - etc/di.xml (modify) — add preference if new interface
```

Wait for the user to confirm before proceeding.

## Step 4: Create the files

### email_templates.xml

If the file already exists, add new `<template>` entries. Do not overwrite existing templates.

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Email:etc/email_templates.xsd">
    <template id="<template_id_customer>"
        label="<Label> Email Template Customer"
        file="<filename_customer>.html"
        type="html"
        module="<Vendor>_<Module>"
        area="frontend" />
    <template id="<template_id_internal>"
        label="<Label> Email Template Internal"
        file="<filename_internal>.html"
        type="html"
        module="<Vendor>_<Module>"
        area="frontend" />
</config>
```

### HTML email templates

Create both templates following the project pattern from the existing examples you read in Step 2.

**Internal template** — includes all fields, uses `[ACTION REQUIRED]` subject:
```html
<!--@subject {{trans "[ACTION REQUIRED] <TYPE> - %code" code=$data.code }} @-->
<!--@vars {
"var data.field_one":"Field One Label",
"var data.field_two":"Field Two Label"
} @-->

{{template config_path="design/email/header_template"}}

<div>
Hello {{var data.branch_name}}{{if data.location_found}} Team{{/if}},
<br/>
Please see the <type> below. Please contact the customer at your earliest convenience.
</div>
<br/>
<table class="message-details">
    <tr>
        <td><strong>{{trans "Reference Code"}}</strong></td>
        <td>{{var data.code}}</td>
    </tr>
    <!-- Required fields as <tr> rows -->
    <!-- Optional fields wrapped in {{depend data.field}}...{{/depend}} -->
</table>

{{template config_path="design/email/footer_template"}}
```

**Customer confirmation template** — includes only customer-relevant fields, friendlier tone:
```html
<!--@subject {{trans "<TYPE> CONFIRMATION - %code" code=$data.code }} @-->
<!--@vars { ... } @-->

{{template config_path="design/email/header_template"}}

<div>
Hello {{var data.first_name}} {{var data.last_name}},
<br/>
Thank you for your submission.
Our team will contact you to confirm details.
</div>
<br/>
<table class="message-details">
    <!-- Customer-relevant fields only -->
</table>
<div>
    If you have any questions in the meantime.
    <br/>
    Feel free to reach out to our customer service team at <strong>{{var data.contact_phone}}</strong> or {{var data.support_email}}
</div>

{{template config_path="design/email/footer_template"}}
```

### Important template rules

1. **List every variable** in the `@vars` comment — even conditional ones
2. **Use `{{depend data.field}}`** to hide rows for optional/empty fields
3. **Use `{{trans "Label"}}`** for all labels (translatability)
4. **Never pass arrays/objects directly** to template variables — they render as raw JSON. Deserialise in PHP first and either:
   - Format as an HTML string (e.g. `<ul><li>item</li></ul>`)
   - Create separate scalar template variables per item

### PHP model — email sending methods

Follow the existing model pattern from the project. Add two private methods and one public orchestrator:

```php
private function sendCustomerConfirmationEmail(array $input): void
{
    $storeId = $this->storeManager->getStore()->getId();
    $this->mail->setTemplateIdentifier('<template_id_customer>')
        ->setTemplateOptions([
            'area' => Area::AREA_FRONTEND,
            'store' => Store::DEFAULT_STORE_ID,
        ])
        ->setTemplateVars(['data' => $input])
        ->setFromByScope('general', $storeId)
        ->setReplyTo($input['support_email'])
        ->addTo($input['customer_email'])
        ->getTransport()
        ->sendMessage();
}

private function sendInternalEmail(array $input): void
{
    $storeId = $this->storeManager->getStore()->getId();
    $this->mail->setTemplateIdentifier('<template_id_internal>')
        ->setTemplateOptions([
            'area' => Area::AREA_FRONTEND,
            'store' => Store::DEFAULT_STORE_ID,
        ])
        ->setTemplateVars(['data' => $input])
        ->setFromByScope('general', $storeId)
        ->setReplyTo(
            $input['customer_email'],
            $input['first_name'] . ' ' . $input['last_name']
        )
        ->addTo($input['branch_email'])
        ->addBcc($input['bcc_emails'])
        ->getTransport()
        ->sendMessage();
}

public function sendEmails(array $input): void
{
    $storeDetails = $this->getStoreDetails($input['store_code'] ?? '');
    $input = array_merge($input, $storeDetails);

    $this->sendCustomerConfirmationEmail($input);
    $this->sendInternalEmail($input);
}
```

### Branch routing (getStoreDetails)

Follow the existing `InventorySource` lookup pattern from the project (see CLAUDE.md Reuse rules). Read an existing enquiry model to get the exact implementation:

```php
private function getStoreDetails(string $storeCode): array
{
    // Look up InventorySource by store_code
    // Fall back to general contact config
    // Read BCC from admin config (see CLAUDE.md Reuse rules for the config path convention)
    // Return array with branch_email, branch_name, bcc_emails, contact details
}
```

## Step 5: Verify

Run the project's PHP quality commands from CLAUDE.md Commands section on the new/modified PHP files. Report any issues found.

## Step 6: Remind about admin config

If the module doesn't already have a BCC field in `system.xml`, remind the user to run:

```
/admin-config BCC email address for <module> enquiry emails
```

This creates the admin field that the branch routing logic reads from.
