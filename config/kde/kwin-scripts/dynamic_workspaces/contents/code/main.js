// Dynamic Workspaces KWin Script
// Optimized for KDE Plasma 6 (Kubuntu 26.04) with backwards compatibility for Plasma 5.
// Reconciles desktops: ensures always 1 trailing empty desktop, removes unused empty ones.
// Auto-places new application windows on the next available workspace when current workspace is occupied.

const MIN_DESKTOPS = 2;
const LOG_LEVEL = 2; // 0 trace, 1 debug, 2 info

function log(...args) { print("[dynamic_workspaces] ", ...args); }
function debug(...args) { if (LOG_LEVEL <= 1) log(...args); }
function trace(...args) { if (LOG_LEVEL <= 0) log(...args); }

let guardDepth = 0;
let dragInProgress = false;
let isInitializing = true;
const wiredClientIds = new Set();

const isKde6 = typeof workspace !== "undefined" && typeof workspace.windowList === "function";

const compat = isKde6
	? {
		addDesktop: () => {
			workspace.createDesktop(workspace.desktops.length, undefined);
		},
		windowList: () => workspace.windowList(),
		windowAddedSignal: () => workspace.windowAdded,
		windowRemovedSignal: () => workspace.windowRemoved,
		desktopChangedSignal: client => client.desktopsChanged,
		workspaceDesktops: () => workspace.desktops,
		desktopAmount: () => workspace.desktops.length,
		lastDesktop: () => {
			const ds = workspace.desktops;
			return ds.length ? ds[ds.length - 1] : null;
		},
		deleteLastDesktop: () => {
			const desktops = workspace.desktops;
			if (!desktops.length) return;
			const last = desktops[desktops.length - 1];
			if (!last) return;

			const current = workspace.currentDesktop;
			const idx = desktops.indexOf(current);
			const fallback = (idx + 1 < desktops.length || idx === -1)
				? desktops[idx + 1]
				: current;

			if (fallback) workspace.currentDesktop = fallback;
			workspace.removeDesktop(last);
			if (current && current !== last) {
				workspace.currentDesktop = current;
			}
		},
		clientDesktops: c => c.desktops || [],
		setClientDesktops: (c, ds) => { c.desktops = ds; },
		clientOnDesktop: (c, d) => {
			if (!d) return false;
			if (!c.desktops || c.desktops.length === 0) {
				return d === workspace.currentDesktop;
			}
			return c.desktops.indexOf(d) !== -1;
		},
		currentDesktopIndex: () => {
			const ds = workspace.desktops;
			return ds.indexOf(workspace.currentDesktop);
		},
		setCurrentDesktopByIndex: (idx) => {
			const ds = workspace.desktops;
			if (idx >= 0 && idx < ds.length) {
				workspace.currentDesktop = ds[idx];
			}
		},
		setClientDesktopByIndex: (c, idx) => {
			const ds = workspace.desktops;
			if (idx >= 0 && idx < ds.length) {
				c.desktops = [ds[idx]];
			}
		},
	}
	: {
		addDesktop: () => {
			workspace.createDesktop(workspace.desktops, "dyndesk");
		},
		windowList: () => workspace.clientList(),
		windowAddedSignal: () => workspace.clientAdded,
		windowRemovedSignal: () => workspace.clientRemoved,
		desktopChangedSignal: client => client.desktopChanged,
		workspaceDesktops: () => {
			let r = [];
			for (let i = 0; i < workspace.desktops; ++i) {
				r.push({ index: i });
			}
			return r;
		},
		desktopAmount: () => workspace.desktops,
		lastDesktop: () => ({ index: workspace.desktops - 1 }),
		deleteLastDesktop: () => {
			workspace.removeDesktop(workspace.desktops - 1);
		},
		clientDesktops: c => (c.x11DesktopIds ? c.x11DesktopIds.map(id => ({ index: id - 1 })) : [{ index: (c.desktop || workspace.currentDesktop) - 1 }]),
		setClientDesktops: (c, ds) => {
			if (ds.length && ds[0]) {
				c.desktop = ds[0].index + 1;
			}
		},
		clientOnDesktop: (c, d) => {
			if (!d) return false;
			const desk = c.desktop || workspace.currentDesktop;
			return desk === d.index + 1;
		},
		currentDesktopIndex: () => {
			return workspace.currentDesktop - 1;
		},
		setCurrentDesktopByIndex: (idx) => {
			workspace.currentDesktop = idx + 1;
		},
		setClientDesktopByIndex: (c, idx) => {
			c.desktop = idx + 1;
		},
	};

function isNormalAppWindow(c) {
	if (!c) return false;
	if (c.skipPager || c.skipTaskbar || c.onAllDesktops) return false;
	if (c.transient) return false;
	if (typeof c.normalWindow !== "undefined" && !c.normalWindow) return false;
	if (typeof c.specialWindow !== "undefined" && c.specialWindow) return false;
	return true;
}

function desktopHasOtherWindows(idx, excludeClient) {
	const desktops = compat.workspaceDesktops();
	const d = desktops[idx];
	if (!d) return false;

	const clients = compat.windowList();
	const excludeId = excludeClient ? (isKde6 ? excludeClient.internalId : excludeClient.windowId) : null;

	for (const c of clients) {
		if (!isNormalAppWindow(c)) continue;
		const cid = isKde6 ? c.internalId : c.windowId;
		if (excludeId && cid === excludeId) continue;
		if (compat.clientOnDesktop(c, d)) {
			return true;
		}
	}
	return false;
}

function desktopIsEmpty(idx) {
	return !desktopHasOtherWindows(idx, null);
}

function autoMoveToNextWorkspace(client) {
	if (guardDepth > 0 || isInitializing) return;
	if (!isNormalAppWindow(client)) return;

	const currentIdx = compat.currentDesktopIndex();
	if (currentIdx < 0) return;

	// If current workspace already has other windows, auto-place this window on the next empty workspace
	if (desktopHasOtherWindows(currentIdx, client)) {
		guardDepth++;
		try {
			let targetIdx = -1;
			const total = compat.desktopAmount();
			for (let i = currentIdx + 1; i < total; i++) {
				if (!desktopHasOtherWindows(i, client)) {
					targetIdx = i;
					break;
				}
			}

			if (targetIdx === -1) {
				compat.addDesktop();
				targetIdx = compat.desktopAmount() - 1;
			}

			debug(`Auto-moving window to workspace ${targetIdx + 1}`);
			compat.setClientDesktopByIndex(client, targetIdx);
			compat.setCurrentDesktopByIndex(targetIdx);

			if (isKde6 && typeof workspace.activeWindow !== "undefined") {
				workspace.activeWindow = client;
			} else if (typeof workspace.activeClient !== "undefined") {
				workspace.activeClient = client;
			}
		} finally {
			guardDepth--;
		}
	}
}

function ensureTrailingEmpty() {
	if (guardDepth > 0) return;

	const count = compat.desktopAmount();
	if (count < MIN_DESKTOPS) {
		guardDepth++;
		try {
			while (compat.desktopAmount() < MIN_DESKTOPS) {
				compat.addDesktop();
			}
		} finally {
			guardDepth--;
		}
		return;
	}

	if (!desktopIsEmpty(count - 1)) {
		guardDepth++;
		try {
			compat.addDesktop();
			debug("Appended new empty workspace");
		} finally {
			guardDepth--;
		}
	}
}

function shiftWindowsDown(idx) {
	const desktops = compat.workspaceDesktops();
	compat.windowList().forEach(c => {
		if (c.skipPager || c.onAllDesktops) return;
		const cds = compat.clientDesktops(c);
		if (!cds || !cds.length) return;

		const updated = cds.map(d => {
			const i = isKde6 ? desktops.indexOf(d) : d.index;
			if (i > idx) {
				return isKde6 ? desktops[i - 1] : { index: i - 1 };
			}
			return d;
		});
		compat.setClientDesktops(c, updated);
	});
}

function compactFromEnd() {
	if (guardDepth > 0) return;

	guardDepth++;
	try {
		const total = compat.desktopAmount();
		if (total <= MIN_DESKTOPS) return;

		// Check desktops from second-to-last down to 0
		for (let i = total - 1; i >= 0; i--) {
			if (compat.desktopAmount() <= MIN_DESKTOPS) break;

			// If last desktop is empty AND second-to-last is also empty, prune last
			if (i === compat.desktopAmount() - 1) {
				if (desktopIsEmpty(i) && desktopIsEmpty(i - 1)) {
					compat.deleteLastDesktop();
					debug(`Pruned trailing excess empty desktop at ${i}`);
				}
			} else if (desktopIsEmpty(i)) {
				// Empty desktop in middle: shift windows left and prune last
				shiftWindowsDown(i);
				compat.deleteLastDesktop();
				debug(`Compacted empty middle desktop at ${i}`);
			}
		}
	} finally {
		guardDepth--;
	}
}

function compactPreservingIndex() {
	if (dragInProgress || guardDepth > 0) return;

	const desktops = compat.workspaceDesktops();
	const current = workspace.currentDesktop;
	if (!current) return;

	const oldIndex = isKde6 ? desktops.indexOf(current) : (workspace.currentDesktop - 1);

	compactFromEnd();

	if (oldIndex === -1) return;

	const newDesktops = compat.workspaceDesktops();
	if (!newDesktops.length) return;

	const targetIndex = Math.min(oldIndex, newDesktops.length - 1);
	if (isKde6) {
		const target = newDesktops[targetIndex];
		if (target && target !== workspace.currentDesktop) {
			guardDepth++;
			try {
				workspace.currentDesktop = target;
			} finally {
				guardDepth--;
			}
		}
	} else {
		const targetNumber = targetIndex + 1;
		if (workspace.currentDesktop !== targetNumber) {
			workspace.currentDesktop = targetNumber;
		}
	}
}

function reconcile() {
	if (guardDepth > 0 || dragInProgress) return;
	ensureTrailingEmpty();
	compactPreservingIndex();
}

function wireClient(client) {
	if (!client || client.skipPager) return;

	const id = isKde6 ? client.internalId : client.windowId;
	if (id && wiredClientIds.has(id)) return;
	if (id) wiredClientIds.add(id);

	if (client.interactiveMoveResizeStarted) {
		client.interactiveMoveResizeStarted.connect(() => {
			dragInProgress = true;
		});
	}
	if (client.interactiveMoveResizeFinished) {
		client.interactiveMoveResizeFinished.connect(() => {
			dragInProgress = false;
			reconcile();
		});
	}

	compat.desktopChangedSignal(client).connect(() => {
		reconcile();
	});

	if (client.windowClosed) {
		client.windowClosed.connect(() => {
			if (id) wiredClientIds.delete(id);
			reconcile();
		});
	}
}

function onClientAdded(client) {
	if (!client || client.skipPager) return;

	autoMoveToNextWorkspace(client);
	reconcile();
	wireClient(client);
}

if (typeof workspace !== "undefined") {
	// Startup: ensure minimum desktops
	while (compat.desktopAmount() < MIN_DESKTOPS) {
		compat.addDesktop();
	}

	// Connect drag handlers on workspace
	if (workspace.windowStartUserMovedResized) {
		workspace.windowStartUserMovedResized.connect(() => {
			dragInProgress = true;
		});
	}
	if (workspace.windowFinishUserMovedResized) {
		workspace.windowFinishUserMovedResized.connect(() => {
			dragInProgress = false;
			reconcile();
		});
	}

	// Connect existing windows without moving them
	compat.windowList().forEach(wireClient);
	isInitializing = false;

	// Connect future windows with auto-move
	compat.windowAddedSignal().connect(onClientAdded);

	if (compat.windowRemovedSignal()) {
		compat.windowRemovedSignal().connect(() => {
			reconcile();
		});
	}

	workspace.currentDesktopChanged.connect(() => {
		reconcile();
	});

	reconcile();
}
