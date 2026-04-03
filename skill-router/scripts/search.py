#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Skill Router - BM25 search over archived agents/skills registry.
Usage:
    python search.py "keyword"
    python search.py "keyword" --top 5
"""

import csv
import re
import sys
import argparse
from pathlib import Path
from math import log
from collections import defaultdict


DATA_DIR = Path(__file__).parent.parent / "data"
REGISTRY = DATA_DIR / "registry.csv"


class BM25:
    def __init__(self, k1=1.5, b=0.75):
        self.k1 = k1
        self.b = b
        self.corpus = []
        self.doc_lengths = []
        self.avgdl = 0
        self.idf = {}
        self.doc_freqs = defaultdict(int)
        self.N = 0

    def tokenize(self, text):
        text = str(text).lower()
        tokens = re.findall(r'[\u4e00-\u9fff]|[a-z0-9_]+', text)
        return [t for t in tokens if len(t) > 1 or '\u4e00' <= t <= '\u9fff']

    def fit(self, documents):
        self.corpus = [self.tokenize(doc) for doc in documents]
        self.N = len(self.corpus)
        if self.N == 0:
            return
        self.doc_lengths = [len(doc) for doc in self.corpus]
        self.avgdl = sum(self.doc_lengths) / self.N
        for doc in self.corpus:
            seen = set()
            for word in doc:
                if word not in seen:
                    self.doc_freqs[word] += 1
                    seen.add(word)
        for word, freq in self.doc_freqs.items():
            self.idf[word] = log((self.N - freq + 0.5) / (freq + 0.5) + 1)

    def score(self, query):
        query_tokens = self.tokenize(query)
        scores = []
        for idx, doc in enumerate(self.corpus):
            score = 0
            doc_len = self.doc_lengths[idx]
            term_freqs = defaultdict(int)
            for word in doc:
                term_freqs[word] += 1
            for token in query_tokens:
                if token in self.idf:
                    tf = term_freqs[token]
                    idf = self.idf[token]
                    numerator = tf * (self.k1 + 1)
                    denominator = tf + self.k1 * (1 - self.b + self.b * doc_len / self.avgdl)
                    score += idf * numerator / denominator
            scores.append((idx, score))
        return sorted(scores, key=lambda x: x[1], reverse=True)


def search(query, max_results=3):
    if not REGISTRY.exists():
        print(f"ERROR: {REGISTRY} not found")
        sys.exit(1)

    with open(REGISTRY, 'r', encoding='utf-8') as f:
        rows = list(csv.DictReader(f))

    # Name repeated 3x for higher weight — ensures exact name matches rank above
    # description-only matches (e.g. "Game Designer" ranks above "Level Designer")
    documents = [
        f"{row.get('Name','')} {row.get('Name','')} {row.get('Name','')} {row.get('Description','')} {row.get('Keywords','')}"
        for row in rows
    ]

    bm25 = BM25()
    bm25.fit(documents)
    ranked = bm25.score(query)

    print(f"## Results for: {query}\n")
    count = 0
    for idx, score in ranked:
        if score <= 0 or count >= max_results:
            break
        row = rows[idx]
        print(f"**{row['Name']}** ({row['Type']})")
        print(f"  {row['Description'][:120]}")
        print(f"  Path: `{row['Path']}`")
        print(f"  Score: {score:.2f}\n")
        count += 1

    if count == 0:
        print("No matches found.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Search archived agents/skills")
    parser.add_argument("query", help="Search query")
    parser.add_argument("--top", type=int, default=3, help="Max results (default: 3)")
    args = parser.parse_args()
    search(args.query, args.top)
