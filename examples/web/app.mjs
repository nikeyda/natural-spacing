import {
  OrderedTextUpdateSession,
  recommendPolicy,
  resolvePolicy,
} from "@natural-spacing/core";
import { bindNaturalSpacing } from "@natural-spacing/web";

/**
 * Wires one semantic policy model to live keyboard input, secure input, and
 * complete revision-capable ASR hypotheses. The demo uses synthetic text and
 * never logs field values or transcripts.
 */
export function mountNaturalSpacingDemo(root = document) {
  const message = required(root, "[data-message]");
  const password = required(root, "[data-password]");
  const messageStatus = required(root, "[data-message-status]");
  const passwordStatus = required(root, "[data-password-status]");
  const hypothesis = required(root, "[data-asr-hypothesis]");
  const interimButton = required(root, "[data-asr-interim]");
  const finalButton = required(root, "[data-asr-final]");
  const display = required(root, "[data-asr-display]");
  const committed = required(root, "[data-asr-committed]");
  const policyStatus = required(root, "[data-policy-status]");

  const messageContext = { contentKind: "message" };
  const secureContext = {
    explicitPolicy: "naturalLanguage",
    contentKind: "message",
    isSecure: true,
  };
  const asrContext = { contentKind: "asrTranscript" };

  const policies = {
    message: resolvePolicy(messageContext),
    password: resolvePolicy(secureContext),
    asr: resolvePolicy(asrContext),
  };
  const recommendations = {
    message: recommendPolicy(messageContext),
    password: recommendPolicy(secureContext),
    asr: recommendPolicy(asrContext),
  };

  const messageBinding = bindNaturalSpacing(message, { policy: policies.message });
  const passwordBinding = bindNaturalSpacing(password, { policy: policies.password });
  const messageDiagnostics = installInputDiagnostics(
    message,
    messageBinding,
    messageStatus,
  );
  const passwordDiagnostics = installInputDiagnostics(
    password,
    passwordBinding,
    passwordStatus,
    { hideText: true },
  );
  const asrSession = new OrderedTextUpdateSession({
    policy: policies.asr,
    source: "asr",
  });
  const utteranceId = "synthetic-demo-utterance";
  asrSession.start(utteranceId);
  let revision = 0;

  policyStatus.textContent = JSON.stringify({ policies, recommendations });

  const acceptAsr = (stability) => {
    const result = asrSession.accept({
      utteranceId,
      revision,
      text: hypothesis.value,
      stability,
    });
    revision += 1;
    if (result.accepted && result.output !== null) {
      display.textContent = result.output.displayText;
      if (result.output.committedText !== null) {
        committed.textContent = result.output.committedText;
      }
    }
    return result;
  };

  const showInterim = () => acceptAsr("interim");
  const commitFinal = () => acceptAsr("final");
  interimButton.addEventListener("click", showInterim);
  finalButton.addEventListener("click", commitFinal);

  return {
    policies,
    recommendations,
    messageBinding,
    passwordBinding,
    asrSession,
    acceptAsr,
    dispose() {
      interimButton.removeEventListener("click", showInterim);
      finalButton.removeEventListener("click", commitFinal);
      messageDiagnostics.dispose();
      passwordDiagnostics.dispose();
      messageBinding.dispose();
      passwordBinding.dispose();
      asrSession.cancel(utteranceId);
    },
  };
}

function installInputDiagnostics(control, binding, output, { hideText = false } = {}) {
  let composing = false;
  let lastEvent = "ready";
  let lastInputType = "none";

  const render = () => {
    const selection = control.selectionStart === null || control.selectionEnd === null
      ? "unavailable"
      : `${control.selectionStart}..${control.selectionEnd}/${control.selectionDirection}`;
    output.textContent = [
      `configuredPolicy=${binding.adapter.policy}`,
      `effectivePolicy=${binding.adapter.effectivePolicy}`,
      `text=${hideText ? "<hidden>" : control.value}`,
      `selection=${selection}`,
      `composing=${composing}`,
      `decision=${binding.adapter.lastPlan?.decision ?? "none"}`,
      `event=${lastEvent}`,
      `inputType=${lastInputType}`,
    ].join("\n");
  };

  const onEvent = (event) => {
    if (event.type === "compositionstart") composing = true;
    if (event.type === "compositionend") composing = false;
    lastEvent = event.type;
    lastInputType = event instanceof InputEvent && event.inputType
      ? event.inputType
      : "none";
    render();
  };
  const eventNames = [
    "beforeinput",
    "input",
    "compositionstart",
    "compositionupdate",
    "compositionend",
    "select",
    "focus",
    "blur",
  ];
  for (const eventName of eventNames) control.addEventListener(eventName, onEvent);
  render();

  return {
    dispose() {
      for (const eventName of eventNames) control.removeEventListener(eventName, onEvent);
    },
  };
}

function required(root, selector) {
  const element = root.querySelector(selector);
  if (element === null) throw new Error(`Missing demo element: ${selector}`);
  return element;
}

if (typeof document !== "undefined" && document.querySelector("[data-natural-spacing-demo]")) {
  globalThis.naturalSpacingDemo = mountNaturalSpacingDemo(document);
}
