# Stage 6 Manual Test Scenarios

This document contains manual test scenarios for Stage 6 Intent-Driven Retrieval.

## Purpose

These scenarios help verify that Stage 6 correctly retrieves relevant records based on user queries.

## How to Test

1. Create test records in each Space
2. Ask the queries listed below
3. Verify that only relevant records are retrieved
4. Verify that fewer than 10 records are returned on average

---

## Health Space Test Scenarios

### Scenario 1: Blood Pressure Query

**Query:** "What is my blood pressure?"

**Expected Results:**
- Only blood pressure records returned
- Records contain keywords: "blood", "pressure"
- Fewer than 10 records
- Most recent records prioritized

**Test Data Needed:**
- 5 blood pressure records
- 5 medication records
- 5 lab result records

---

### Scenario 2: Medication Query

**Query:** "Show my medications"

**Expected Results:**
- Only medication records returned
- Records contain keywords: "medication", "medicine", "drug"
- Fewer than 10 records
- Most recent records prioritized

**Test Data Needed:**
- 5 medication records
- 5 blood pressure records
- 5 symptom records

---

### Scenario 3: Recent Lab Results

**Query:** "Recent lab results"

**Expected Results:**
- Only lab result records returned
- Records contain keywords: "lab", "test", "result"
- Fewer than 10 records
- Most recent records prioritized

**Test Data Needed:**
- 5 lab result records
- 5 checkup records
- 5 other health records

---

## Finance Space Test Scenarios

### Scenario 1: Expense Query

**Query:** "Show my expenses"

**Expected Results:**
- Only expense records returned
- Records contain keywords: "expense", "spent", "cost"
- Fewer than 10 records
- Most recent records prioritized

**Test Data Needed:**
- 5 expense records (groceries, gas, shopping)
- 5 income records
- 5 investment records

---

### Scenario 2: Grocery Spending

**Query:** "What did I spend on groceries?"

**Expected Results:**
- Only grocery expense records returned
- Records contain keywords: "grocery", "groceries", "food"
- Fewer than 10 records
- Most recent records prioritized

**Test Data Needed:**
- 5 grocery expense records
- 5 other expense records
- 5 income records

---

### Scenario 3: Income Query

**Query:** "My income this month"

**Expected Results:**
- Only income records returned
- Records contain keywords: "income", "salary", "payment"
- Fewer than 10 records
- Current month records prioritized

**Test Data Needed:**
- 5 income records
- 5 expense records
- 5 investment records

---

## Success Criteria

For all scenarios above, verify:

### Performance
- ✅ Query analysis completes in < 50ms
- ✅ Relevance scoring completes in < 100ms
- ✅ Total retrieval time < 200ms

### Accuracy
- ✅ Only relevant records returned
- ✅ No irrelevant records included
- ✅ Records match query keywords

### Efficiency
- ✅ Fewer than 10 records returned on average
- ✅ 30% fewer records than Stage 4
- ✅ Token usage reduced by 30%

### Multi-Language Support
- ✅ Works with English queries
- ✅ Works with Russian queries
- ✅ Works with Uzbek queries
- ✅ Works with mixed language records

### Fallback Behavior
- ✅ Falls back to Stage 4 when query is empty
- ✅ Falls back to Stage 4 when config disabled
- ✅ No crashes or errors

---

## Notes

- Test with realistic data
- Test in multiple languages
- Test edge cases (empty queries, very long queries)
- Measure token savings vs Stage 4
- Collect user feedback

---

**Last Updated:** December 1, 2025