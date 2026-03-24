> **[EXAMPLE - Magento 2 + React]** This concept doc is from a Magento 2 + React project. It will be deleted when you run `/setup-project`. It serves as an example of the kind of architecture knowledge you should capture for your own project.

# reCAPTCHA integration pattern

The project supports both reCAPTCHA V2 (checkbox) and V3 (invisible) for form mutations. The pattern:

1. **PHP:** A ViewModel exposes the configured reCAPTCHA type via a method (e.g. `getRecaptchaTypeFor<Feature>()`)
2. **PHTML:** Passes the type as a `data-recaptcha-type` attribute on the widget container
3. **React:** A reCAPTCHA wrapper component reads the type and renders the appropriate V2 or V3 widget
4. **Submission:** The token is included in the GraphQL mutation; Magento's reCAPTCHA module validates it server-side

**Stale closure bug:** The reCAPTCHA component's `onTokenGenerated` callback can capture a stale reference if the parent re-renders between reCAPTCHA load and user interaction. The fix is to use a `useRef` that always points to the latest callback. This pattern applies to any React callback registered with an external SDK that runs outside React's render cycle.
