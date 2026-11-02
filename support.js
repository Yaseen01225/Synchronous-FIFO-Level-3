// ============================================================================
// GENERATED FILE
// Source: dc-runtime/src/*.ts
// Build command: bun build.ts
// Note: Do not edit this generated file directly.
// ============================================================================

"use strict";

(() => {

    // ------------------------------------------------------------------------
    // Object property utilities
    // ------------------------------------------------------------------------

    var Mt = Object.defineProperty;

    var Tt = (t, n, e) =>
        n in t
            ? Mt(t, n, {
                enumerable: !0,
                configurable: !0,
                writable: !0,
                value: e
            })
            : t[n] = e;

    var T = (t, n, e) =>
        Tt(
            t,
            typeof n != "symbol" ? n + "" : n,
            e
        );

    // ------------------------------------------------------------------------
    // React access functions
    // ------------------------------------------------------------------------

    function L() {

        const t = window.React;

        if (!t) {
            throw new Error(
                "dc-runtime: window.React is not available yet"
            );
        }

        return t;
    }

    function Lt() {

        const t = window.ReactDOM;

        if (!t) {
            throw new Error(
                "dc-runtime: window.ReactDOM is not available yet"
            );
        }

        return t;
    }

    // ------------------------------------------------------------------------
    // React element creation
    // ------------------------------------------------------------------------

    var A = ((...t) =>
        L().createElement(...t)
    );

    // ------------------------------------------------------------------------
    // Extract Design Component information
    // ------------------------------------------------------------------------

    function Ot(t) {

        const n = t.querySelector("x-dc");

        if (!n) {
            return null;
        }

        const e = t.querySelector(
            "script[data-dc-script]"
        );

        const {
            props: o,
            preview: r
        } = B(
            e?.getAttribute("data-props") ?? null
        );

        return {
            template: n.innerHTML,
            js: e && e.textContent || "",
            props: o,
            preview: r
        };
    }

    // ------------------------------------------------------------------------
    // Extract component information from HTML text
    // ------------------------------------------------------------------------

    function tt(t) {

        const n = /<x-dc(?:\s[^>]*)?>/.exec(t);

        if (!n) {
            return null;
        }

        const e = t.lastIndexOf("</x-dc>");

        if (e === -1 || e < n.index) {
            return null;
        }

        const o = t.slice(
            n.index + n[0].length,
            e
        );

        const s = new DOMParser()
            .parseFromString(t, "text/html")
            .querySelector("script[data-dc-script]");

        const {
            props: i,
            preview: a
        } = B(
            s?.getAttribute("data-props") ?? null
        );

        return {
            template: o,
            js: s && s.textContent || "",
            props: i,
            preview: a
        };
    }

    // ------------------------------------------------------------------------
    // Parse component properties
    // ------------------------------------------------------------------------

    function B(t) {

        if (!t) {
            return {
                props: null,
                preview: null
            };
        }

        let n;

        try {
            n = JSON.parse(t);
        }
        catch {
            return {
                props: null,
                preview: null
            };
        }

        if (
            !n ||
            typeof n !== "object" ||
            Array.isArray(n)
        ) {
            return {
                props: null,
                preview: null
            };
        }

        const e = n;

        const o =
            e.$preview &&
            typeof e.$preview === "object"
                ? e.$preview
                : null;

        const r = {};

        for (const s of Object.keys(e)) {

            if (s[0] !== "$") {
                r[s] = e[s];
            }
        }

        return {
            props: Object.keys(r).length ? r : null,
            preview: o
        };
    }

    // ------------------------------------------------------------------------
    // Extract component name from a URL
    // ------------------------------------------------------------------------

    function Pt(t) {

        let n = t || "";

        try {
            n = decodeURIComponent(n);
        }
        catch {}

        return (
            n.split("/").pop() || "Root"
        )
        .replace(/\.dc\.html$|\.html?$/, "") || "Root";
    }

    // ------------------------------------------------------------------------
    // CSS definitions
    // ------------------------------------------------------------------------

    var Dt = `
        .sc-placeholder {
            background: color-mix(
                in srgb,
                currentColor 8%,
                transparent
            );

            border: 1px solid color-mix(
                in srgb,
                currentColor 50%,
                transparent
            );

            border-radius: 2px;
            box-sizing: border-box;
            overflow: hidden;
        }

        @keyframes sc-shine {
            0% {
                background-position: 100% 50%;
            }

            100% {
                background-position: 0% 50%;
            }
        }

        html.sc-dc-streaming .sc-placeholder,
        html.sc-dc-streaming .sc-interp.sc-missing {
            position: relative;

            background: color-mix(
                in srgb,
                currentColor 5%,
                transparent
            );

            border-color: transparent;
        }
    `;

    var jt =
        "html,body{height:100%;margin:0}" +
        "#dc-root,#dc-root>.sc-host{height:100%}";

    // Remaining runtime implementation continues...

})();