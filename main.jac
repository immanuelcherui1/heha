"""heha-movers - Entry Point.

Combines server-side endpoints with the client-side UI.
"""

import from endpoints { marketplace }

# Client-side UI
cl {
    import from .frontend { app as ClientApp }

    def:pub app -> JsxElement {
        return <ClientApp/>;
    }
}
