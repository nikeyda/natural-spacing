package dev.naturalspacing.core

import java.io.File
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.int
import kotlinx.serialization.json.long
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

fun main(args: Array<String>) {
    val root = File(args.single())
    var checks = 0

    document(root, "rules-v1.json")["cases"]!!.jsonArray.forEach { element ->
        val value = element.jsonObject
        val id = value.string("id")
        val expected = value.string("expected")
        val actual = NaturalSpacing.normalize(value.string("input"), policy(value.string("policy")))
        require(actual == expected) { "$id: expected '$expected', got '$actual'" }
        require(NaturalSpacing.normalize(actual, policy(value.string("policy"))) == actual) { "$id: not idempotent" }
        checks++
    }

    document(root, "sessions-v1.json")["scenarios"]!!.jsonArray.forEach { scenarioElement ->
        val scenario = scenarioElement.jsonObject
        val session = NaturalSpacingSession()
        scenario["steps"]!!.jsonArray.forEachIndexed { index, stepElement ->
            val step = stepElement.jsonObject
            val exchange = step["exchange"]!!.jsonObject
            val actual = session.process(snapshot(exchange["snapshot"]!!.jsonObject))
            val expected = plan(exchange["expectedPlan"]!!.jsonObject)
            require(actual == expected) { "${scenario.string("id")} step ${index + 1}: $actual != $expected" }
            val count = step["expectedSession"]!!.jsonObject.int("suppressedBoundaryCount")
            require(session.suppressedBoundaryCount == count) { "${scenario.string("id")} step ${index + 1}: suppression count" }
            checks++
        }
    }

    document(root, "policy-v1.json")["cases"]!!.jsonArray.forEach { element ->
        val value = element.jsonObject
        val context = policyContext(value["context"]!!.jsonObject)
        val actual = recommendPolicy(context)
        val expected = recommendation(value["expected"]!!.jsonObject)
        require(actual == expected) { "${value.string("id")}: $actual != $expected" }
        val resolved = resolvePolicy(context)
        require(resolved == if (expected.autoApply) expected.policy else FieldPolicy.VERBATIM) {
            "${value.string("id")}: unsafe automatic resolution $resolved"
        }
        if (value.string("id") == "search-query-is-a-recommendation") {
            require(resolvePolicy(context, FieldPolicy.NATURAL_LANGUAGE) == FieldPolicy.NATURAL_LANGUAGE)
        }
        checks++
    }

    document(root, "text-updates-v1.json")["cases"]!!.jsonArray.forEach { element ->
        val value = element.jsonObject
        val actual = formatTextUpdate(textUpdate(value["update"]!!.jsonObject))
        val expected = formattedTextUpdate(value["expected"]!!.jsonObject)
        require(actual == expected) { "${value.string("id")}: $actual != $expected" }
        checks++
    }

    var orderedChecks = 0
    document(root, "ordered-text-sessions-v1.json")["scenarios"]!!.jsonArray.forEach { scenarioElement ->
        val scenario = scenarioElement.jsonObject
        val orderedSession = OrderedTextUpdateSession(
            policy(scenario.string("policy")),
            enumValueOf(camelToEnum(scenario.string("source"))),
        )
        scenario["operations"]!!.jsonArray.forEachIndexed { index, operationElement ->
            val operation = operationElement.jsonObject
            val expected = operation["expected"]!!.jsonObject
            when (operation.string("kind")) {
                "start" -> require(
                    orderedSession.start(operation.string("utteranceId")) == expected.boolean("started"),
                ) { "${scenario.string("id")} operation ${index + 1}: start" }
                "cancel" -> require(
                    orderedSession.cancel(operation.string("utteranceId")) == expected.boolean("cancelled"),
                ) { "${scenario.string("id")} operation ${index + 1}: cancel" }
                "accept" -> {
                    val actual = orderedSession.accept(orderedTextUpdateEvent(operation["event"]!!.jsonObject))
                    val expectedResult = orderedTextUpdateResult(expected)
                    require(actual == expectedResult) {
                        "${scenario.string("id")} operation ${index + 1}: $actual != $expectedResult"
                    }
                }
                else -> error("Unknown ordered operation ${operation.string("kind")}")
            }
            orderedChecks++
        }
    }

    val proposed = NaturalSpacing.planProposedEdit(
        ProposedEdit(
            text = "中文",
            range = TextRange(1, 0),
            replacementText = "A",
            editKind = EditKind.INSERT,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ),
    )
    require(proposed.replacementText == " A " && proposed.plan.resultText == "中 A 文")
    val difference = proposedEditReplacingDifference(
        beforeText = "中🙂文",
        afterText = "中🙂A文",
        policy = FieldPolicy.NATURAL_LANGUAGE,
    )
    require(difference?.range == TextRange(3, 0) && difference.replacementText == "A")
    val session = NaturalSpacingSession()
    val deletion = session.processProposedEdit(
        ProposedEdit(
            text = "中 A",
            range = TextRange(1, 1),
            replacementText = "",
            editKind = EditKind.DELETE,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ),
    )
    require(deletion.plan.decision == PlanDecision.SUPPRESSED && !deletion.requiresReplacement)
    val composing = NaturalSpacing.planProposedEdit(
        ProposedEdit(
            text = "中",
            range = TextRange(1, 0),
            replacementText = "A",
            composingRange = TextRange(1, 1),
            editKind = EditKind.INSERT,
            policy = FieldPolicy.NATURAL_LANGUAGE,
        ),
    )
    require(composing.plan.decision == PlanDecision.COMPOSING && !composing.requiresReplacement)
    checks += 4

    var graphemeChecks = 0
    File(root, "spec/unicode/17.0.0/GraphemeBreakTest.txt").forEachLine { rawLine ->
        val sequence = rawLine.substringBefore('#').trim()
        if (!sequence.startsWith('÷')) return@forEachLine
        val text = StringBuilder()
        val expected = mutableListOf<Int>()
        sequence.split(Regex("\\s+")).forEach { token ->
            when (token) {
                "÷" -> expected += text.length
                "×" -> Unit
                else -> text.appendCodePoint(token.toInt(16))
            }
        }
        val actual = Grapheme17.boundaries(text.toString()).toList()
        require(actual == expected) {
            "GraphemeBreakTest case ${graphemeChecks + 1}: $actual != $expected"
        }
        graphemeChecks++
    }
    require(graphemeChecks == 766) {
        "Expected 766 GraphemeBreakTest cases, found $graphemeChecks"
    }

    println(
        "Kotlin conformance passed: ${checks - 4} shared fixture checks + 4 bridge checks + " +
            "$orderedChecks ordered text-update checks + " +
            "$graphemeChecks Unicode 17 grapheme checks, " +
            "Java runtime ${System.getProperty("java.version")}",
    )
}

private fun document(root: File, name: String): JsonObject = Json.parseToJsonElement(
    File(root, "spec/fixtures/$name").readText(),
).jsonObject

private fun snapshot(value: JsonObject) = EditSnapshot(
    value.string("beforeText"),
    value.string("afterUserText"),
    range(value["changedRange"]!!.jsonObject),
    selection(value["selection"]!!.jsonObject),
    value["composingRange"].nullableObject()?.let(::range),
    editKind(value.string("editKind")),
    policy(value.string("policy")),
    value.nullableInt("maxLengthUtf16"),
)

private fun plan(value: JsonObject) = EditPlan(
    decision(value.string("decision")),
    value["insertions"]!!.jsonArray.map { insertion ->
        val item = insertion.jsonObject
        Insertion(item.int("offset"), reason(item.string("reason")))
    },
    value.string("resultText"),
    selection(value["selection"]!!.jsonObject),
)

private fun policyContext(value: JsonObject) = PolicyContext(
    value.nullableString("explicitPolicy")?.let(::policy),
    value.nullableString("contentKind")?.let(::contentKind),
    value.nullableString("text"),
    value.nullableBoolean("isSecure"),
)

private fun recommendation(value: JsonObject) = PolicyRecommendation(
    policy(value.string("policy")),
    enumValueOf(value.string("confidence").uppercase()),
    enumValueOf(camelToEnum(value.string("source"))),
    enumValueOf(camelToEnum(value.string("reason"))),
    value.boolean("autoApply"),
)

private fun textUpdate(value: JsonObject) = TextUpdate(
    value.string("text"),
    policy(value.string("policy")),
    enumValueOf(camelToEnum(value.string("source"))),
    enumValueOf(camelToEnum(value.string("stability"))),
)

private fun formattedTextUpdate(value: JsonObject) = FormattedTextUpdate(
    value.string("displayText"),
    value.nullableString("committedText"),
    value.boolean("changed"),
    policy(value.string("policy")),
    enumValueOf(camelToEnum(value.string("source"))),
    enumValueOf(camelToEnum(value.string("stability"))),
)

private fun orderedTextUpdateEvent(value: JsonObject) = OrderedTextUpdateEvent(
    value.string("utteranceId"),
    value.long("revision"),
    value.string("text"),
    enumValueOf(camelToEnum(value.string("stability"))),
)

private fun orderedTextUpdateResult(value: JsonObject) = OrderedTextUpdateResult(
    value.boolean("accepted"),
    enumValueOf(camelToEnum(value.string("reason"))),
    value["output"].nullableObject()?.let(::formattedTextUpdate),
)

private fun range(value: JsonObject) = TextRange(value.int("start"), value.int("length"))
private fun selection(value: JsonObject) = TextSelection(value.int("anchor"), value.int("focus"))

private fun policy(value: String) = when (value) {
    "naturalLanguage" -> FieldPolicy.NATURAL_LANGUAGE
    "verbatim" -> FieldPolicy.VERBATIM
    else -> error("Unknown policy $value")
}

private fun editKind(value: String): EditKind = enumValueOf(camelToEnum(value))
private fun decision(value: String): PlanDecision = enumValueOf(camelToEnum(value))
private fun reason(value: String): InsertionReason = enumValueOf(camelToEnum(value))
private fun contentKind(value: String): ContentKind = enumValueOf(camelToEnum(value))

private fun camelToEnum(value: String): String = value.replace(Regex("([a-z0-9])([A-Z])"), "$1_$2").uppercase()
private fun JsonObject.string(key: String) = getValue(key).jsonPrimitive.content
private fun JsonObject.int(key: String) = getValue(key).jsonPrimitive.int
private fun JsonObject.long(key: String) = getValue(key).jsonPrimitive.long
private fun JsonObject.boolean(key: String) = getValue(key).jsonPrimitive.boolean
private fun JsonObject.nullableString(key: String) = get(key).takeUnless { it == null || it is JsonNull }?.jsonPrimitive?.content
private fun JsonObject.nullableInt(key: String) = get(key).takeUnless { it == null || it is JsonNull }?.jsonPrimitive?.int
private fun JsonObject.nullableBoolean(key: String) = get(key).takeUnless { it == null || it is JsonNull }?.jsonPrimitive?.boolean
private fun JsonElement?.nullableObject(): JsonObject? = takeUnless { it == null || it is JsonNull }?.jsonObject
