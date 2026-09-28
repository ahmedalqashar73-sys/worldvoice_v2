// Only economy_config/current controls payouts; no production values in code.
const fail = (message, status = 400) => { throw Object.assign(new Error(message), {status}); };
const pos = (n) => Number.isSafeInteger(n) && n > 0;
export function approvedPayoutWindows(policy, now) {
  const days = policy.payoutWindows;
  if (!Array.isArray(days) || days.length !== 2 ||
      !days.every(day => Number.isSafeInteger(day) && day >= 1 && day <= 28) ||
      days[0] === days[1]) {
    fail("Two payout windows must be configured in economy_config.", 503);
  }
  // Reporting is UTC; the window is not itself permission to pay out.
  const next = [];
  for (let months = 0; months < 3; months++) {
    const first = new Date(Date.UTC(
      now.getUTCFullYear(), now.getUTCMonth() + months, 1,
    ));
    for (const day of days) {
      const d = new Date(Date.UTC(first.getUTCFullYear(), first.getUTCMonth(), day));
      if (d.getTime() > now.getTime()) next.push(d.toISOString().slice(0, 10));
    }
  }
  return next.sort()[0];
}

export function withdrawalQuote(policy, amount, now) {
  if (!pos(amount) || !pos(policy.minWithdrawalDiamonds) ||
      amount < policy.minWithdrawalDiamonds) {
    fail("Withdrawal below configured minimum.");
  }
  if (!Array.isArray(policy.withdrawalMethods) ||
      policy.withdrawalMethods.length === 0) {
    fail("No withdrawal methods have been configured.", 503);
  }
  const grossUsd = amount * policy.diamondUsdValue;
  const feeUsd = grossUsd * policy.withdrawalFeePercent / 100;
  const netUsd = grossUsd - feeUsd;
  if (![grossUsd, feeUsd, netUsd].every(Number.isFinite) || netUsd <= 0) {
    fail("Invalid withdrawal conversion.", 503);
  }
  return {
    diamonds: amount,
    grossUsd: Math.round(grossUsd * 100) / 100,
    feeUsd: Math.round(feeUsd * 100) / 100,
    netUsd: Math.round(netUsd * 100) / 100,
    payoutWindow: approvedPayoutWindows(policy, now),
  };
}

