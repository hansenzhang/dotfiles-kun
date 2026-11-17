# Logic prototype

A logic prototype is one self-contained HTML file that lets anyone run a state model by clicking buttons. Use it when the question is about business logic, state transitions, or the shape of data: designs that look fine on paper but turn out wrong once you run real cases through them.

The file needs nothing installed, so you can send it to someone who doesn't write code, such as a designer, a product manager, or a domain expert, and let them try the model themselves. Write it in their terms, not the code's.

## When to use it

- "I'm not sure this state machine handles the case where X happens and then Y."
- "Can this data model represent the case where..."
- "I want to try out what the API should look like before writing it."
- Any case where someone wants to press buttons and watch the state change.

If the question is "what should this look like", use [UI.md](UI.md) instead.

## Process

### 1. State the question

Before writing code, write down which state model you are prototyping and what question it answers. Put this paragraph in a visible introduction at the top of the page, not in a code comment. A prototype that answers the wrong question is wasted work, so the question must be visible for checking later, whether the user is watching now or reads it later.

### 2. Put the logic in its own module

Put the logic that answers the question in one `<script>` block, written as a small pure module that could be copied into the real codebase later. The page around it is throwaway. The module isn't.

Pick the form that fits the question:

- A pure reducer, `(state, action) => state`. Use it when actions are discrete events and the state is a single value.
- A state machine with explicit states and transitions. Use it when "which actions are allowed right now" is part of the question.
- A few pure functions over a plain data type. Use it when there is no current state, only transformations.
- A class or module with a clear set of methods. Use it when the logic really does own internal state over time.

Choose the form that fits the question, not the one that is easiest to connect to a page. Keep the module pure: no DOM, no `document`, and no button handlers inside it. The page calls the module, and the module never calls the page. That way, once the question is answered, the confirmed reducer, state machine, or functions can be copied into the real module unchanged.

### 3. Build the HTML file

Write one file of plain HTML, CSS, and JavaScript, with everything inline and no framework, bundler, or server. It must open with a double-click and still work after being sent by email.

Write it for someone who doesn't write code. Every label uses the domain's terms, so buttons and state read like the business, not like the reducer. Explain what is happening in plain words.

Lay it out from top to bottom:

1. A title, and one line saying what the demo lets you explore. This is the question from step 1.
2. The current state, shown as a readable panel of labelled fields rather than raw JSON. Re-render it after every click so the change is visible. Where it helps the reader, highlight what just changed.
3. Free-play buttons, one per action and always available, so anyone can try the actions in any order. Each click dispatches its action and re-renders the state.
4. Guided walkthroughs, one scenario per tab. Each tab has a short plain-language description of the scenario, saying what it sets up and what to watch for, followed by the buttons to press in order. Each step is a real button that performs its action and moves to the next step. Starting a walkthrough resets the state, so the scenario runs the same way every time.

Pick scenarios that show the cases that are hard to work out on paper: the normal path, a tricky edge case, and an attempt at something that should be forbidden.

Keep the styling simple and clean: readable type, generous spacing, and one accent color. Add no animations or decoration that draws attention away from the state and the buttons.

### 4. Hand it over

Send the user the file or open it for them. They will click through the walkthroughs and free play when they have time. Watch for moments like "wait, that shouldn't be possible" or "I assumed X would be different". Those are flaws in the design, and finding them is the purpose of the prototype. If they want new actions or scenarios, add them.

### 5. Record the answer and the prototype

Once the prototype has answered its question, record the answer, then keep the prototype as [SKILL.md](SKILL.md) describes. For a logic prototype, copy the confirmed reducer, state machine, or functions into the real module. Commit the HTML file to the throwaway branch that keeps the prototype. Because it is one self-contained file, it still runs from there.

## Mistakes to avoid

- Adding tests. A prototype that needs tests is no longer a prototype.
- Connecting it to the real database. Keep state in memory unless the question is about storage.
- Generalizing. Don't plan for "what if we want X later". The prototype answers one question.
- Mixing the logic into the page. If the module touches the DOM, `document`, or button handlers, it can't be copied out. Keep the page a thin layer over a pure module.
- Using a framework, bundler, or server. The recipient double-clicks one file, and a React app or a dev server makes that impossible.
- Shipping the HTML page to production. The page exists for clicking through by hand. The logic module behind it is the part to keep.
