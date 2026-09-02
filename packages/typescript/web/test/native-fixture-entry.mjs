import { bindNaturalSpacing } from "../dist/index.js";

document.body.innerHTML = `
  <input id="input" type="text">
  <input id="password" type="password">
  <textarea id="textarea"></textarea>
`;

const bindings = new Map();
window.attachNaturalSpacing = (id, options = { policy: "naturalLanguage" }) => {
  bindings.get(id)?.dispose();
  const control = document.getElementById(id);
  const binding = bindNaturalSpacing(control, options);
  bindings.set(id, binding);
  return binding.adapter;
};
window.disposeNaturalSpacing = (id) => {
  bindings.get(id)?.dispose();
  bindings.delete(id);
};
window.naturalSpacingReady = true;
