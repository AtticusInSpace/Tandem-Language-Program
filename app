// language_matcher.js

/**
 * Solves the language exchange matching problem using Mixed Integer Programming.
 * Uses javascript-lp-solver (https://github.com/JWally/jsLPSolver)
 */

import solver from 'javascript-lp-solver';

export function generateMatchingModel(participants, weights = { first: 10, second: 7, third: 5 }) {
  const model = {
    optimize: 'score',
    opType: 'max',
    constraints: {},
    variables: {},
    ints: {},
  };

  // Build mapping
  const indexMap = {};
  participants.forEach((p, i) => indexMap[p.name] = i);

  // Helper to get score from match
  function getScore(teachLangs, learnLang) {
    if (!learnLang) return 0;
    if (teachLangs[0] && teachLangs[0] === learnLang) return weights.first;
    if (teachLangs[1] && teachLangs[1] === learnLang) return weights.second;
    if (teachLangs[2] && teachLangs[2] === learnLang) return weights.third;
    return 0;
  }

  // For each pair, define a binary variable if mutual match is possible
  participants.forEach((p1, i) => {
    participants.forEach((p2, j) => {
      if (i >= j) return;

      const p1Learns = [p1.learn_lang1, p1.learn_lang2, p1.learn_lang3].filter(Boolean);
      const p1Teaches = [p1.teach_lang1, p1.teach_lang2, p1.teach_lang3].filter(Boolean);
      const p2Learns = [p2.learn_lang1, p2.learn_lang2, p2.learn_lang3].filter(Boolean);
      const p2Teaches = [p2.teach_lang1, p2.teach_lang2, p2.teach_lang3].filter(Boolean);

      const match1 = p1Learns.find(lang => p2Teaches.includes(lang));
      const match2 = p2Learns.find(lang => p1Teaches.includes(lang));

      if (match1 && match2) {
        const varName = `x_${i}_${j}`;
        const score = getScore(p2Teaches, match1) + getScore(p1Teaches, match2);

        model.variables[varName] = {
          score,
          [`p_${i}`]: 1,
          [`p_${j}`]: 1,
        };
        model.ints[varName] = 1;

        model.constraints[`p_${i}`] = { max: 1 };
        model.constraints[`p_${j}`] = { max: 1 };
      }
    });
  });

  return model;
}

export function solveMatching(participants, weights) {
  const model = generateMatchingModel(participants, weights);
  const results = solver.Solve(model);
  const matches = [];

  for (const key in results) {
    if (key.startsWith('x_') && results[key] === 1) {
      const [_, i, j] = key.split('_');
      matches.push({
        participant1: participants[parseInt(i)],
        participant2: participants[parseInt(j)],
        score: model.variables[key].score
      });
    }
  }

  return { matches, totalScore: results.result };
}
