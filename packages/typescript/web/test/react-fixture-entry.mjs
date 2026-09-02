import { createElement, useEffect, useLayoutEffect, useRef, useState } from "react";
import { createRoot } from "react-dom/client";

import { bindNaturalSpacing } from "../dist/index.js";

function useNaturalSpacingBinding(ref, renderedValue) {
  const bindingRef = useRef(null);

  useLayoutEffect(() => {
    const control = ref.current;
    if (control === null) return undefined;
    const binding = bindNaturalSpacing(control, { policy: "naturalLanguage" });
    bindingRef.current = binding;
    return () => {
      binding.dispose();
      bindingRef.current = null;
    };
  }, [ref]);

  useLayoutEffect(() => {
    bindingRef.current?.adapter.sync();
  }, [renderedValue]);
}

function ControlledInput() {
  const [value, setValue] = useState("中");
  const ref = useRef(null);
  useNaturalSpacingBinding(ref, value);

  return createElement(
    "section",
    null,
    createElement("input", {
      id: "react-controlled",
      ref,
      value,
      onChange: (event) => setValue(event.currentTarget.value),
    }),
    createElement("output", { id: "react-controlled-state" }, value),
    createElement(
      "button",
      { id: "react-controlled-reset", type: "button", onClick: () => setValue("文") },
      "Reset",
    ),
  );
}

function UncontrolledInput() {
  const ref = useRef(null);
  useNaturalSpacingBinding(ref, undefined);
  return createElement("input", {
    id: "react-uncontrolled",
    ref,
    defaultValue: "中",
  });
}

function App() {
  useEffect(() => {
    window.reactFixtureReady = true;
  }, []);
  return createElement(
    "main",
    null,
    createElement(ControlledInput),
    createElement(UncontrolledInput),
  );
}

createRoot(document.querySelector("#root")).render(createElement(App));
