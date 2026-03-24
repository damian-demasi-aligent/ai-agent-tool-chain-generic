> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# FormWizard cross-step data sharing

A multi-step `FormWizard<T>` component accumulates each step's validated data as the user progresses, but only exposes the current step's data type to the active step component. This creates a challenge when a later step needs data from an earlier one (e.g. Step 2 needs to know which items were selected in Step 1).

The project solves this via DOM data attributes: the parent form writes earlier step data into a `data-*` attribute on the container div, and the later step reads it via a `ref`.

```
Step 1 (selects items) → FormWizard stores formData
                       → preFilledContentRender writes data-selected-items="Item A,Item B"
Step 2 → reads container's data attribute via stepRef.current
```

**Trade-off:** This couples two components through the DOM rather than through props or context. It works, but means the components can't be tested in isolation without mocking DOM attributes. If you're building a new form wizard and need cross-step data, consider whether a shared context provider would be cleaner.
