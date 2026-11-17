# UI prototype

Build several very different versions of a UI on one route, with a bar at the bottom of the page that switches between them. The user flips between versions in the browser, picks one or combines parts of several, and the rest get thrown away.

If the question is about logic or state rather than appearance, use [LOGIC.md](LOGIC.md) instead.

## When to use it

- "What should this page look like?"
- "I want to see a few options for this dashboard before I commit."
- "Try a different layout for the settings screen."
- Any time the user would otherwise spend a day choosing between three vague mockups in their head.

## Two options, and option A is strongly preferred

A UI prototype is much easier to judge inside the rest of the app, with the real header, sidebar, data, and density. On an empty route, every version looks fine. Use option A whenever an existing page could host the versions. Use option B only when the prototype has no reasonable existing home.

### Option A: change an existing page (preferred)

The route already exists. Render the versions on that route, chosen by a `?variant=` URL search parameter. The existing data fetching, parameters, and auth stay as they are, and only the rendering changes. This is the default unless you have a specific reason to do otherwise.

If the thing you are prototyping has no page yet but would naturally sit inside one, such as a new dashboard section, a new card on the settings screen, or a new step in an existing flow, it is still option A. Render the versions inside the host page.

### Option B: a new page (last resort)

Use this only when the thing you are prototyping has no existing page to sit in, such as a new top-level screen or a flow that can't be embedded anywhere reasonable.

Create a throwaway route that follows the project's existing routing convention. Don't add a new top-level structure. Make the name show that it is a prototype, for example by putting `prototype` in the path or file name. Use the same `?variant=` parameter.

Before choosing option B, check again that no existing page could host it. An empty route hides design problems that a full page would show.

Both options use the same switcher bar.

## Process

### 1. State the question and choose how many versions

Build three versions by default, and never more than five. Beyond five, the versions stop being very different and become noise.

Write the plan in one line, in the prototype's location or in a comment at the top of the file:

> "Three versions of the settings page, switched by `?variant=`, on the existing `/settings` route."

The user can push back on it now or read it later.

### 2. Build very different versions

Draft each version. Each one must:

- Serve the page's purpose with the data the page has.
- Use the project's component library or styling system, such as Tailwind CSS, shadcn, MUI, or plain CSS.
- Export a component with a clear name, such as `VariantA`, `VariantB`, or `VariantC`.

The versions must differ in structure: layout, information hierarchy, and the main control the user acts on, not only colors. Three slightly different card grids teach the user nothing. If two drafts come out too alike, redo one with an explicit instruction such as "do not use a card grid".

### 3. Connect them

Create one switcher component on the route:

```tsx
// Pseudo-code. Adapt it to the project's framework.
const variant = searchParams.get('variant') ?? 'A';
return (
  <>
    {variant === 'A' && <VariantA {...data} />}
    {variant === 'B' && <VariantB {...data} />}
    {variant === 'C' && <VariantC {...data} />}
    <PrototypeSwitcher variants={['A','B','C']} current={variant} />
  </>
);
```

For option A, keep all the existing data fetching above the switcher, so only the rendered tree changes between versions.

For option B, the throwaway route under `/prototype/<name>` renders the same switcher.

### 4. Build the switcher bar

The switcher is a small bar fixed at the bottom center of the screen, with three parts:

- A left arrow that goes to the previous version, wrapping from the first to the last.
- A label with the current version's key and, if the version exports a name, that name too, for example `B (Sidebar layout)`.
- A right arrow that goes to the next version, wrapping from the last to the first.

It behaves like this:

- Clicking an arrow updates the URL search parameter through the framework's router, for example `router.replace` in Next.js or `navigate` in React Router, so the version survives a reload and can be shared as a link.
- The left and right arrow keys also switch versions, except when an `<input>`, `<textarea>`, or `[contenteditable]` element has focus.
- It looks clearly separate from the page, for example a high-contrast pill with a light shadow, so nobody mistakes it for part of the design.
- It is hidden in production builds. Check `process.env.NODE_ENV !== 'production'` or the equivalent, so a prototype merged by mistake can't show the bar to users.

Put the switcher in one shared component that both options can use, wherever the project keeps shared UI.

### 5. Hand it over

Give the user the URL and the `?variant=` keys. They will flip through the versions when they have time. The most useful feedback usually sounds like "I want the header from B with the sidebar from C", and that combination is the design they want.

### 6. Record the answer and clean up

Once a version wins, record which one and why, then keep the prototype as [SKILL.md](SKILL.md) describes. Move the winner into the real code, and commit the rest to the throwaway branch, not main:

- For option A, merge the winning version into the existing page, and remove the other versions and the switcher from main.
- For option B, turn the winning version into a real route, and remove the throwaway route and the switcher from main.

Keep the full set of versions on the throwaway branch as the record of what was tried. Don't leave them on main, where unused version components and the switcher go stale and confuse the next reader.

## Mistakes to avoid

- Versions that differ only in color or wording. That is a tweak, not a prototype. Real versions differ in structure.
- Sharing too much code between versions. A shared `<Header>` is fine, but a shared `<Layout>` defeats the purpose. Each version must be free to change the layout.
- Connecting versions to real writes. Read-only versions are fine. If a version needs to change data, point it at a stub, because the question is what the page should look like, not whether the backend works.
- Shipping the prototype code to production. It was written without tests and with minimal error handling. Rewrite it properly when you move it into the real code.
