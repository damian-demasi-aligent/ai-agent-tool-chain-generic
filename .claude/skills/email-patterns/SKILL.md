---
name: email-patterns
description: Magento 2 transactional email patterns. Use when creating or modifying email templates, TransportBuilder calls, email_templates.xml, or any feature that sends transactional emails.
user-invocable: false
metadata:
  capabilities: [magento]
---

# Magento 2 Email Patterns

Follow these conventions when creating or modifying transactional email functionality. Before starting, **read the project rules** (`.claude/rules/`) for project-specific email conventions (routing, BCC handling, template variable format, enquiry codes, etc.) and check the reference implementations listed in the Reuse Before Reimplementing table.

## Architecture Overview

Transactional emails in Magento 2 follow this flow:

```
GraphQL Resolver → Model (implements Interface) → TransportBuilder → HTML template
                                                  ↕
                                         ScopeConfig (config-driven routing, BCC)
```

Check the project rules (`.claude/rules/`) for how many emails each form submission sends (e.g. customer confirmation + internal notification) and any project-specific routing patterns.

## File Structure

Every email feature requires these files:

| File | Purpose |
|---|---|
| `etc/email_templates.xml` | Declares template IDs and maps them to HTML files |
| `view/frontend/email/<name>.html` | HTML template with Magento template directives |
| `Model/<Name>.php` | PHP class with `TransportBuilder` email sending logic |
| `Api/<Name>Interface.php` | Service contract interface for the model |
| `etc/di.xml` | Preference mapping interface → implementation |

## email_templates.xml

Declare each template with a unique ID, label, filename, and module:

```xml
<?xml version="1.0"?>
<config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="urn:magento:module:Magento_Email:etc/email_templates.xsd">
    <template id="<module>_email_template_<recipient>"
        label="<Module> Email Template <Recipient>"
        file="<module>_email_template_<recipient>.html"
        type="html"
        module="<Vendor>_<Module>"
        area="frontend" />
</config>
```

**Naming convention:** `<domain>_<purpose>_email_template_<recipient>` — e.g. `trial_request_email_template_customer`, `service_enquiry_email_template_internal`.

## HTML Email Templates

Templates live in `view/frontend/email/` and use Magento's template directive syntax.

### Required structure

```html
<!--@subject {{trans "<Subject Line> - %code" code=$data.code }} @-->
<!--@vars {
"var data.field_name":"Field Label",
"var data.another_field":"Another Label"
} @-->

{{template config_path="design/email/header_template"}}

<div>
Hello {{var data.recipient_name}},
<br/>
Body text here.
</div>
<br/>
<table class="message-details">
    <tr>
        <td><strong>{{trans "Field Label"}}</strong></td>
        <td>{{var data.field_name}}</td>
    </tr>
</table>

{{template config_path="design/email/footer_template"}}
```

### Template directives

| Directive | Usage |
|---|---|
| `{{var data.field}}` | Output a variable (auto-escaped) |
| `{{trans "Text"}}` | Translatable string |
| `{{trans "Text %var" var=$data.field}}` | Translatable string with variable substitution |
| `{{depend data.field}}...{{/depend}}` | Show block only if field is non-empty |
| `{{if data.field}}...{{else}}...{{/if}}` | Conditional rendering |
| `{{template config_path="..."}}` | Include header/footer templates |

### Critical rules

1. **Only scalar values render correctly.** Arrays and objects render as raw JSON. Deserialise structured data in PHP and either format as HTML or create separate template variables.
2. **The `@vars` comment block** is required — it tells Magento's admin template editor which variables are available. List every variable the template uses.
3. **The `@subject` comment** defines the email subject line. Use `{{trans}}` for translatability.
4. **Check the project rules** (`.claude/rules/`) for any subject line prefix conventions (e.g. `[ACTION REQUIRED]` for internal emails).

## TransportBuilder Pattern

The PHP model sends emails using `TransportBuilder`. Follow this pattern:

```php
private function sendEmail(array $input, string $templateId, string $toEmail): void
{
    $storeId = $this->storeManager->getStore()->getId();
    $this->mail->setTemplateIdentifier($templateId)
        ->setTemplateOptions([
            'area' => Area::AREA_FRONTEND,
            'store' => Store::DEFAULT_STORE_ID,
        ])
        ->setTemplateVars(['data' => $input])
        ->setFromByScope('general', $storeId)
        ->setReplyTo($replyToEmail, $replyToName)
        ->addTo($toEmail)
        ->getTransport()
        ->sendMessage();
}
```

**Important:** Check the project rules (`.claude/rules/`) for the project's template variable convention. Many projects pass a single `['data' => $input]` array rather than individual top-level variables.

### Email routing

Check the project rules (`.claude/rules/`) for project-specific routing patterns. Common patterns include:

- **Direct routing** — send to a fixed admin-configured email
- **Branch/source routing** — look up the destination email from an entity (e.g. inventory source, store) based on form input
- **BCC from admin config** — read a comma-separated config value and parse into an array

When a project-specific routing pattern exists in the project rules, always follow it rather than inventing a new mechanism.

## Common Dependencies

Email model classes typically inject:

```php
public function __construct(
    private readonly ScopeConfigInterface $scopeConfig,
    private readonly TransportBuilder $mail,
    private readonly StoreManagerInterface $storeManager,
    // Add project-specific dependencies (e.g. source repositories for branch routing)
) {}
```

Check the reference implementations listed in the Reuse Before Reimplementing table in `.claude/rules/` for the full set of dependencies used in this project.

## Reference Code

Before writing any email functionality, **read the existing email implementations listed in the Reuse Before Reimplementing table** (in `.claude/rules/`). These are the authoritative patterns for:

- Constructor dependencies
- Email routing logic
- BCC handling
- Enquiry/reference code generation
- Template variable structure
