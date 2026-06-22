import 'package:flutter/material.dart';

import '../../core/models/build_configuration.dart';
import '../../core/models/build_log_entry.dart';
import '../../l10n/app_localizations.dart';
import 'section.dart';

class BuildPanel extends StatefulWidget {
  const BuildPanel({
    required this.selectedTargets,
    required this.isBuilding,
    required this.progress,
    required this.roadmapSteps,
    required this.log,
    required this.onBuild,
    this.configuration,
    super.key,
  });

  final int selectedTargets;
  final bool isBuilding;
  final int progress;
  final List<BuildRoadmapStep> roadmapSteps;
  final List<BuildLogEntry> log;
  final VoidCallback onBuild;
  final BuildConfiguration? configuration;

  @override
  State<BuildPanel> createState() => _BuildPanelState();
}

enum _BuildDisplayMode { visual, commands }

enum _VisualRoadmapMode { full, simplified }

class _BuildPanelState extends State<BuildPanel> {
  _BuildDisplayMode _displayMode = _BuildDisplayMode.visual;
  _VisualRoadmapMode _visualMode = _VisualRoadmapMode.full;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remainingSeconds = _estimatedRemainingSeconds(widget.roadmapSteps);

    return Section(
      title: l10n.build,
      icon: Icons.play_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<_BuildDisplayMode>(
                segments: [
                  ButtonSegment(
                    value: _BuildDisplayMode.visual,
                    label: Text(l10n.visualBuildMode),
                    icon: const Icon(Icons.account_tree_outlined),
                  ),
                  ButtonSegment(
                    value: _BuildDisplayMode.commands,
                    label: Text(l10n.commandsBuildMode),
                    icon: const Icon(Icons.terminal_outlined),
                  ),
                ],
                selected: {_displayMode},
                onSelectionChanged: (selection) {
                  setState(() {
                    _displayMode = selection.single;
                  });
                },
              ),
              if (_displayMode == _BuildDisplayMode.visual)
                SegmentedButton<_VisualRoadmapMode>(
                  segments: [
                    ButtonSegment(
                      value: _VisualRoadmapMode.full,
                      label: Text(l10n.fullRoadmapMode),
                      icon: const Icon(Icons.view_agenda_outlined),
                    ),
                    ButtonSegment(
                      value: _VisualRoadmapMode.simplified,
                      label: Text(l10n.simplifiedRoadmapMode),
                      icon: const Icon(Icons.view_list_outlined),
                    ),
                  ],
                  selected: {_visualMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _visualMode = selection.single;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.selectedTargets(widget.selectedTargets),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (widget.isBuilding || widget.progress > 0) ...[
            LinearProgressIndicator(
              value: widget.progress / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _BuildStatusChip(
                  icon: Icons.percent,
                  label: l10n.overallProgressLabel(widget.progress),
                ),
                if (widget.isBuilding && remainingSeconds != null)
                  _BuildStatusChip(
                    icon: Icons.schedule_outlined,
                    label: l10n.buildRemainingTime(remainingSeconds),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: widget.isBuilding || widget.selectedTargets == 0
                  ? null
                  : widget.onBuild,
              icon: Icon(
                widget.isBuilding
                    ? Icons.hourglass_top_outlined
                    : Icons.rocket_launch_outlined,
              ),
              label: Text(
                widget.isBuilding ? l10n.building : l10n.buildInstallers,
              ),
            ),
          ),
          if (widget.roadmapSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            if (_displayMode == _BuildDisplayMode.visual)
              _BuildRoadmap(steps: _visualRoadmapSteps(widget.roadmapSteps))
            else
              _BuildCommands(
                steps: widget.roadmapSteps,
                configuration: widget.configuration,
              ),
          ] else if (_displayMode == _BuildDisplayMode.commands) ...[
            const SizedBox(height: 16),
            Text(
              l10n.noBuildCommands,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (widget.log.isNotEmpty) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(l10n.technicalLog),
              initiallyExpanded: false,
              children: [
                for (final entry in widget.log) _LogEntryTile(entry: entry),
              ],
            ),
          ],
        ],
      ),
    );
  }

  int? _estimatedRemainingSeconds(List<BuildRoadmapStep> steps) {
    if (steps.isEmpty) {
      return null;
    }

    var total = 0.0;
    for (final step in steps) {
      final estimate = step.estimatedSeconds;
      if (estimate == null || estimate <= 0) {
        continue;
      }

      switch (step.state) {
        case BuildRoadmapStepState.pending:
          total += estimate;
        case BuildRoadmapStepState.running:
          final progressRatio = step.progress.clamp(0, 100) / 100;
          total += estimate * (1 - progressRatio);
        case BuildRoadmapStepState.success:
        case BuildRoadmapStepState.warning:
        case BuildRoadmapStepState.skipped:
          break;
      }
    }

    return total.round();
  }

  List<BuildRoadmapStep> _expandVisualRoadmap(
    List<BuildRoadmapStep> parentSteps,
  ) {
    final result = <BuildRoadmapStep>[];
    var number = 1;
    for (final parent in parentSteps) {
      final definitions =
          _visualSubsteps[parent.id] ??
          [_VisualSubstep(parent.id, parent.title, parent.description)];
      for (var index = 0; index < definitions.length; index++) {
        final definition = definitions[index];
        final start = index * 100 / definitions.length;
        final end = (index + 1) * 100 / definitions.length;
        final state = _substepState(parent, index, definitions.length, end);
        final progress = state == BuildRoadmapStepState.running
            ? (((parent.progress - start) / (end - start)) * 100)
                  .clamp(0, 100)
                  .round()
            : state == BuildRoadmapStepState.success
            ? 100
            : 0;
        result.add(
          BuildRoadmapStep(
            id: definition.id,
            number: number++,
            title: definition.title,
            description: definition.description,
            state: state,
            progress: progress,
            estimatedSeconds: parent.estimatedSeconds == null
                ? null
                : (parent.estimatedSeconds! / definitions.length).ceil(),
            detail:
                state == BuildRoadmapStepState.running ||
                    (parent.state != BuildRoadmapStepState.running &&
                        index == definitions.length - 1)
                ? parent.detail
                : null,
          ),
        );
      }
    }
    return result;
  }

  List<BuildRoadmapStep> _visualRoadmapSteps(
    List<BuildRoadmapStep> parentSteps,
  ) {
    return switch (_visualMode) {
      _VisualRoadmapMode.full => _expandVisualRoadmap(parentSteps),
      _VisualRoadmapMode.simplified => parentSteps,
    };
  }

  BuildRoadmapStepState _substepState(
    BuildRoadmapStep parent,
    int index,
    int count,
    double end,
  ) {
    return switch (parent.state) {
      BuildRoadmapStepState.pending => BuildRoadmapStepState.pending,
      BuildRoadmapStepState.running =>
        parent.progress >= end
            ? BuildRoadmapStepState.success
            : parent.progress >= index * 100 / count
            ? BuildRoadmapStepState.running
            : BuildRoadmapStepState.pending,
      BuildRoadmapStepState.success => BuildRoadmapStepState.success,
      BuildRoadmapStepState.warning =>
        index == count - 1
            ? BuildRoadmapStepState.warning
            : BuildRoadmapStepState.success,
      BuildRoadmapStepState.skipped => BuildRoadmapStepState.skipped,
    };
  }
}

class _VisualSubstep {
  const _VisualSubstep(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;
}

const _visualSubsteps = <String, List<_VisualSubstep>>{
  'project': [
    _VisualSubstep(
      'project:validate',
      'Validate project',
      'Check pubspec.yaml and project structure.',
    ),
    _VisualSubstep(
      'project:metadata',
      'Read metadata',
      'Read version, name and release settings.',
    ),
    _VisualSubstep(
      'project:export',
      'Prepare export',
      'Validate and create the export directory.',
    ),
  ],
  'workspace': [
    _VisualSubstep(
      'workspace:create',
      'Create workspace',
      'Create an isolated temporary build directory.',
    ),
    _VisualSubstep(
      'workspace:copy',
      'Copy sources',
      'Copy project files without generated caches.',
    ),
    _VisualSubstep(
      'workspace:overrides',
      'Apply settings',
      'Apply window, icon and application-id overrides.',
    ),
  ],
  'local-build': [
    _VisualSubstep(
      'local-build:dependencies',
      'Resolve dependencies',
      'Run Flutter dependency resolution.',
    ),
    _VisualSubstep(
      'local-build:compile',
      'Compile Flutter',
      'Compile Dart code and Flutter assets in release mode.',
    ),
    _VisualSubstep(
      'local-build:native',
      'Link native runner',
      'Build plugins and the native Linux runner.',
    ),
  ],
  'bundle': [
    _VisualSubstep(
      'bundle:locate',
      'Locate bundle',
      'Find the generated release/bundle directory.',
    ),
    _VisualSubstep(
      'bundle:executable',
      'Find executable',
      'Identify and validate the main executable.',
    ),
    _VisualSubstep(
      'bundle:icon',
      'Embed icon',
      'Copy the selected window icon into the bundle.',
    ),
  ],
  'rpm': [
    _VisualSubstep(
      'rpm:tree',
      'RPM tree',
      'Create the rpmbuild directory structure.',
    ),
    _VisualSubstep(
      'rpm:metadata',
      'RPM metadata',
      'Create the desktop entry and package icon.',
    ),
    _VisualSubstep(
      'rpm:spec',
      'RPM spec',
      'Generate package metadata and installation rules.',
    ),
    _VisualSubstep(
      'rpm:build',
      'Run rpmbuild',
      'Build and validate the binary RPM package.',
    ),
    _VisualSubstep(
      'rpm:export',
      'Export RPM',
      'Copy the RPM artifact to the export directory.',
    ),
  ],
  'appimage': [
    _VisualSubstep(
      'appimage:appdir',
      'Create AppDir',
      'Create the AppImage filesystem layout.',
    ),
    _VisualSubstep(
      'appimage:apprun',
      'Create AppRun',
      'Write the portable application launcher.',
    ),
    _VisualSubstep(
      'appimage:desktop',
      'Desktop integration',
      'Add desktop metadata, id and icon.',
    ),
    _VisualSubstep(
      'appimage:package',
      'Run appimagetool',
      'Compress AppDir into one AppImage file.',
    ),
    _VisualSubstep(
      'appimage:export',
      'Finalize AppImage',
      'Mark the result executable and export it.',
    ),
  ],
  'targz': [
    _VisualSubstep(
      'targz:archive',
      'Create archive',
      'Compress the release bundle with tar and gzip.',
    ),
    _VisualSubstep(
      'targz:verify',
      'Verify archive',
      'Confirm the tar.gz artifact was exported.',
    ),
  ],
  'deb-container': [
    _VisualSubstep(
      'deb-container:runtime',
      'Container runtime',
      'Resolve Docker or Podman.',
    ),
    _VisualSubstep(
      'deb-container:image',
      'DEB builder image',
      'Verify the cached Debian builder image.',
    ),
    _VisualSubstep(
      'deb-container:start',
      'Start builder',
      'Mount project, export and dependency cache volumes.',
    ),
  ],
  'deb-build': [
    _VisualSubstep(
      'deb-build:dependencies',
      'DEB dependencies',
      'Resolve Flutter packages inside Debian.',
    ),
    _VisualSubstep(
      'deb-build:compile',
      'Compile in Debian',
      'Build the Linux release bundle in the builder.',
    ),
    _VisualSubstep(
      'deb-build:bundle',
      'Locate DEB bundle',
      'Find the builder release bundle and executable.',
    ),
  ],
  'deb-package': [
    _VisualSubstep(
      'deb-package:layout',
      'Debian layout',
      'Create DEBIAN, /opt and desktop directories.',
    ),
    _VisualSubstep(
      'deb-package:control',
      'Control metadata',
      'Write package version, dependencies and maintainer.',
    ),
    _VisualSubstep(
      'deb-package:desktop',
      'DEB integration',
      'Install desktop entry and application icon.',
    ),
    _VisualSubstep(
      'deb-package:build',
      'Run dpkg-deb',
      'Assemble the final Debian package.',
    ),
    _VisualSubstep(
      'deb-package:export',
      'Export DEB',
      'Write the DEB artifact to the export directory.',
    ),
  ],
  'windows-kit': [
    _VisualSubstep(
      'windows-kit:layout',
      'Windows kit layout',
      'Create project, scripts, Inno and assets folders.',
    ),
    _VisualSubstep(
      'windows-kit:project',
      'Copy Windows project',
      'Copy the prepared Flutter project.',
    ),
    _VisualSubstep(
      'windows-kit:scripts',
      'Write Windows scripts',
      'Generate PowerShell and Inno Setup configuration.',
    ),
    _VisualSubstep(
      'windows-kit:archive',
      'Archive Windows kit',
      'Create the transferable Windows build zip.',
    ),
  ],
  'summary': [
    _VisualSubstep(
      'summary:verify',
      'Verify artifacts',
      'Check generated files in the export directory.',
    ),
    _VisualSubstep(
      'summary:report',
      'Build summary',
      'Report successful and failed package targets.',
    ),
  ],
  'cleanup': [
    _VisualSubstep(
      'cleanup:ownership',
      'Prepare cleanup',
      'Restore temporary file ownership when required.',
    ),
    _VisualSubstep(
      'cleanup:remove',
      'Remove workspace',
      'Delete temporary sources and packaging files.',
    ),
  ],
};

class _BuildCommands extends StatelessWidget {
  const _BuildCommands({required this.steps, required this.configuration});

  final List<BuildRoadmapStep> steps;
  final BuildConfiguration? configuration;

  @override
  Widget build(BuildContext context) {
    final configuration = this.configuration;
    if (configuration == null || configuration.projectPath.trim().isEmpty) {
      return Text(
        context.l10n.selectProjectForCommands,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    final groups = <_CommandGroupData>[];
    var nextCommandNumber = 1;
    for (var index = 0; index < steps.length; index++) {
      final commands = _commandsForStep(
        steps[index].id,
        configuration,
      ).map(_normalizeCommand).toList();
      if (commands.isEmpty) {
        continue;
      }
      groups.add(
        _CommandGroupData(
          step: steps[index],
          commands: commands,
          firstCommandNumber: nextCommandNumber,
          color: _groupColor(index),
        ),
      );
      nextCommandNumber += commands.length;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          _CommandGroup(group: groups[index]),
          if (index != groups.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  List<String> _commandsForStep(
    String stepId,
    BuildConfiguration configuration,
  ) {
    final project = configuration.projectPath;
    final output = configuration.outputPath?.trim().isNotEmpty == true
        ? configuration.outputPath!.trim()
        : '$project/build/pack_foundry';
    final appName = configuration.appName.trim().isEmpty
        ? 'Flutter App'
        : configuration.appName.trim();
    final packageName = _slugify(appName);
    final version = _releaseVersion(configuration.releaseTag);
    final icon = configuration.iconPath?.trim() ?? '';
    final maintainer = configuration.developerEmail.trim().isEmpty
        ? 'PackFoundry User <user@localhost>'
        : configuration.developerEmail.trim();
    final description = configuration.description.trim().isEmpty
        ? '$appName packaged with PackFoundry'
        : configuration.description.trim();
    final desktopId = 'dev.packfoundry.${packageName.replaceAll('-', '_')}';

    if (stepId == 'workspace') {
      final commands = <String>[
        r'mkdir -p "$WORKSPACE"',
        r'cp -a "$PROJECT/." "$WORKSPACE/"',
        r'rm -rf "$WORKSPACE/build" "$WORKSPACE/.dart_tool" "$WORKSPACE/.git"',
        r'''sed -Ei "s/set\\(APPLICATION_ID[[:space:]]+[^)]*\\)/set(APPLICATION_ID $DESKTOP_ID)/" "$WORKSPACE/linux/CMakeLists.txt"''',
      ];
      final width = configuration.windowWidth;
      final height = configuration.windowHeight;
      if (width != null && height != null && width > 0 && height > 0) {
        commands.add(
          '''sed -Ei 's/gtk_window_set_default_size\\([^;]+/gtk_window_set_default_size(window, $width, $height)/' "\$WORKSPACE/linux/runner/my_application.cc"''',
        );
      }
      if (icon.isNotEmpty) {
        final extension = icon.toLowerCase().endsWith('.svg') ? 'svg' : 'png';
        commands.addAll([
          r'mkdir -p "$WORKSPACE/.pack_foundry"',
          'cp "\$ICON" "\$WORKSPACE/.pack_foundry/icon.$extension"',
          'WORKSPACE_ICON=${_shellQuote('.pack_foundry/icon.$extension')}',
        ]);
      } else {
        commands.add("WORKSPACE_ICON=''");
      }
      commands.add(r'cd "$WORKSPACE"');
      return commands;
    }

    if (stepId == 'rpm') {
      return const [
        r'RPM_TOP="$WORK_ROOT/rpmbuild"; RPM_ASSETS="$WORK_ROOT/rpm-assets"; RPM_SPEC="$RPM_TOP/SPECS/$PACKAGE_NAME.spec"',
        r'mkdir -p "$RPM_TOP/SPECS" "$RPM_TOP/RPMS" "$RPM_ASSETS"',
        r'''cat > "$RPM_ASSETS/$DESKTOP_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=/opt/$PACKAGE_NAME/$EXECUTABLE_NAME
Icon=$DESKTOP_ID
StartupWMClass=$PACKAGE_NAME
Categories=Utility;
Terminal=false
EOF''',
        r'''if [ -n "$ICON" ]; then
  case "$ICON" in
    *.svg|*.SVG) RPM_ICON="$RPM_ASSETS/$DESKTOP_ID.svg"; RPM_ICON_DEST="/usr/share/icons/hicolor/scalable/apps/$DESKTOP_ID.svg" ;;
    *) RPM_ICON="$RPM_ASSETS/$DESKTOP_ID.png"; RPM_ICON_DEST="/usr/share/icons/hicolor/256x256/apps/$DESKTOP_ID.png" ;;
  esac
  cp "$ICON" "$RPM_ICON"
else
  RPM_ICON="$RPM_ASSETS/$DESKTOP_ID.svg"
  RPM_ICON_DEST="/usr/share/icons/hicolor/scalable/apps/$DESKTOP_ID.svg"
  printf '%s
' '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" rx="48" fill="#0EA5A4"/></svg>' > "$RPM_ICON"
fi''',
        r'''cat > "$RPM_SPEC" <<EOF
%global __brp_check_rpaths %{nil}
Name: $PACKAGE_NAME
Version: $VERSION
Release: 1%{?dist}
Summary: $APP_NAME
License: GPL-2.0-only
Requires: gtk3, libstdc++, xz-libs

%description
$APP_NAME packaged manually from the PackFoundry command plan.

%prep
%build
%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/$PACKAGE_NAME
cp -a "$BUNDLE"/. %{buildroot}/opt/$PACKAGE_NAME/
chmod 755 %{buildroot}/opt/$PACKAGE_NAME/$EXECUTABLE_NAME
install -Dm0644 "$RPM_ASSETS/$DESKTOP_ID.desktop" %{buildroot}/usr/share/applications/$DESKTOP_ID.desktop
install -Dm0644 "$RPM_ICON" %{buildroot}$RPM_ICON_DEST

%files
/opt/$PACKAGE_NAME
/usr/share/applications/$DESKTOP_ID.desktop
/usr/share/icons/hicolor/*/apps/$DESKTOP_ID.*
EOF''',
        r'rpmbuild -bb --define "_topdir $RPM_TOP" "$RPM_SPEC"',
        r'find "$RPM_TOP/RPMS" -type f -name "*.rpm" -exec cp -f {} "$EXPORT/" \;',
      ];
    }

    if (stepId == 'appimage') {
      return const [
        r'APPDIR="$WORK_ROOT/$DESKTOP_ID.AppDir"; rm -rf "$APPDIR"; mkdir -p "$APPDIR/usr/bin"',
        r'cp -a "$BUNDLE/." "$APPDIR/usr/bin/"',
        r'''cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
EXECUTABLE="$(find "$HERE/usr/bin" -maxdepth 1 -type f -perm /111 ! -name '*.so' | head -n 1)"
exec "$EXECUTABLE" "$@"
EOF
chmod +x "$APPDIR/AppRun"''',
        r'''cat > "$APPDIR/$DESKTOP_ID.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=AppRun
Icon=$DESKTOP_ID
StartupWMClass=$PACKAGE_NAME
Categories=Utility;
Terminal=false
EOF''',
        r'''if [ -n "$ICON" ]; then
  case "$ICON" in
    *.svg|*.SVG) APPIMAGE_ICON="$APPDIR/$DESKTOP_ID.svg" ;;
    *) APPIMAGE_ICON="$APPDIR/$DESKTOP_ID.png" ;;
  esac
  cp "$ICON" "$APPIMAGE_ICON"
  cp "$ICON" "$APPDIR/.DirIcon"
else
  APPIMAGE_ICON="$APPDIR/$DESKTOP_ID.svg"
  printf '%s
' '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256"><rect width="256" height="256" rx="48" fill="#0EA5A4"/></svg>' > "$APPIMAGE_ICON"
  cp "$APPIMAGE_ICON" "$APPDIR/.DirIcon"
fi''',
        r'APPIMAGETOOL="$(command -v appimagetool || true)"',
        r'''if [ -z "$APPIMAGETOOL" ]; then
  APPIMAGE_ARCH="$(uname -m)"
  case "$APPIMAGE_ARCH" in
    x86_64|amd64) APPIMAGE_ARCH=x86_64 ;;
    aarch64|arm64) APPIMAGE_ARCH=aarch64 ;;
  esac
  APPIMAGETOOL="$WORK_ROOT/appimagetool-$APPIMAGE_ARCH.AppImage"
  curl -fL "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-$APPIMAGE_ARCH.AppImage" -o "$APPIMAGETOOL"
  chmod +x "$APPIMAGETOOL"
fi''',
        r'ARCH="$(uname -m)" APPIMAGE_EXTRACT_AND_RUN=1 "$APPIMAGETOOL" "$APPDIR" "$EXPORT/$APP_NAME.AppImage"',
        r'chmod +x "$EXPORT/$APP_NAME.AppImage"',
      ];
    }

    if (stepId == 'deb-container') {
      return const [
        r'''DEB_BUILD_SCRIPT='set -euo pipefail
export PATH=/opt/flutter/bin:$PATH
cd /work
rm -rf build/linux
flutter pub get
flutter build linux --release
BUNDLE=$(find build/linux -type d -path "*/release/bundle" | head -n 1)
ARCH=$(dpkg --print-architecture)
ROOT=/tmp/packfoundry-package
rm -rf "$ROOT"
mkdir -p "$ROOT/DEBIAN" "$ROOT/opt/$PACKFOUNDRY_PACKAGE_NAME" "$ROOT/usr/share/applications" "$ROOT/usr/share/icons/hicolor/256x256/apps" "$ROOT/usr/share/icons/hicolor/scalable/apps"
cp -a "$BUNDLE/." "$ROOT/opt/$PACKFOUNDRY_PACKAGE_NAME/"
EXECUTABLE=$(find "$ROOT/opt/$PACKFOUNDRY_PACKAGE_NAME" -maxdepth 1 -type f -perm /111 ! -name "*.so" | head -n 1)
printf "Package: %s
Version: %s
Section: utils
Priority: optional
Architecture: %s
Maintainer: %s
Depends: libgtk-3-0, libstdc++6, liblzma5
Description: %s
" "$PACKFOUNDRY_PACKAGE_NAME" "$PACKFOUNDRY_VERSION" "$ARCH" "$PACKFOUNDRY_MAINTAINER" "$PACKFOUNDRY_DESCRIPTION" > "$ROOT/DEBIAN/control"
printf "[Desktop Entry]
Type=Application
Name=%s
Exec=/opt/%s/%s
Icon=%s
StartupWMClass=%s
Categories=Utility;
Terminal=false
" "$PACKFOUNDRY_APP_NAME" "$PACKFOUNDRY_PACKAGE_NAME" "$(basename "$EXECUTABLE")" "$PACKFOUNDRY_DESKTOP_ID" "$PACKFOUNDRY_PACKAGE_NAME" > "$ROOT/usr/share/applications/$PACKFOUNDRY_DESKTOP_ID.desktop"
if [ -n "$PACKFOUNDRY_ICON_PATH" ] && [ -f "/work/$PACKFOUNDRY_ICON_PATH" ]; then
  case "$PACKFOUNDRY_ICON_PATH" in
    *.svg) cp "/work/$PACKFOUNDRY_ICON_PATH" "$ROOT/usr/share/icons/hicolor/scalable/apps/$PACKFOUNDRY_DESKTOP_ID.svg" ;;
    *) cp "/work/$PACKFOUNDRY_ICON_PATH" "$ROOT/usr/share/icons/hicolor/256x256/apps/$PACKFOUNDRY_DESKTOP_ID.png" ;;
  esac
fi
dpkg-deb --build --root-owner-group "$ROOT" "/out/$PACKFOUNDRY_PACKAGE_NAME-$PACKFOUNDRY_VERSION-$ARCH.deb"' ''',
        r'RUNTIME="$(command -v docker || command -v podman)"',
        r'"$RUNTIME" image inspect packfoundry/deb-builder:bookworm-flutter-stable-v1',
        r'''"$RUNTIME" run --rm -v "$WORKSPACE:/work" -v "$EXPORT:/out" -v packfoundry-pub-cache:/root/.pub-cache -e PACKFOUNDRY_APP_NAME="$APP_NAME" -e PACKFOUNDRY_PACKAGE_NAME="$PACKAGE_NAME" -e PACKFOUNDRY_DESKTOP_ID="$DESKTOP_ID" -e PACKFOUNDRY_VERSION="$VERSION" -e PACKFOUNDRY_MAINTAINER="$MAINTAINER" -e PACKFOUNDRY_DESCRIPTION="$DESCRIPTION" -e PACKFOUNDRY_ICON_PATH="$WORKSPACE_ICON" packfoundry/deb-builder:bookworm-flutter-stable-v1 bash -lc "$DEB_BUILD_SCRIPT"''',
      ];
    }

    if (stepId == 'deb-build') {
      return const [
        r'# Executed inside the DEB container: flutter pub get',
        r'# Executed inside the DEB container: flutter build linux --release',
      ];
    }

    if (stepId == 'deb-package') {
      return const [
        r'# Executed inside the DEB container: dpkg-deb --build --root-owner-group',
      ];
    }

    if (stepId == 'targz') {
      return const [
        r'tar -czf "$EXPORT/$PACKAGE_NAME-linux.tar.gz" -C "$(dirname "$BUNDLE")" "$(basename "$BUNDLE")"',
      ];
    }

    if (stepId == 'windows-kit') {
      return const [
        r'WINDOWS_KIT="$WORK_ROOT/${PACKAGE_NAME}_windows_build_kit"',
        r'mkdir -p "$WINDOWS_KIT/project" "$WINDOWS_KIT/scripts" "$WINDOWS_KIT/inno" "$WINDOWS_KIT/assets"',
        r'cp -a "$WORKSPACE/." "$WINDOWS_KIT/project/"',
        r'printf "%s" "$APP_NAME" > "$WINDOWS_KIT/app_name.txt"; printf "%s" "$PACKAGE_NAME" > "$WINDOWS_KIT/package_name.txt"; printf "%s" "$VERSION" > "$WINDOWS_KIT/version.txt"',
        r'''cat > "$WINDOWS_KIT/scripts/build_windows.ps1" <<'POWERSHELL'
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Project = Join-Path $Root 'project'
$Output = Join-Path $Root 'output'
$AppName = Get-Content (Join-Path $Root 'app_name.txt') -Raw
$PackageName = Get-Content (Join-Path $Root 'package_name.txt') -Raw
$AppVersion = Get-Content (Join-Path $Root 'version.txt') -Raw
New-Item -ItemType Directory -Force -Path $Output | Out-Null
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Flutter SDK is not available in PATH.' }
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is required to install missing Windows build tools.' }
winget install --id Microsoft.VisualStudio.2022.BuildTools --exact --silent --accept-source-agreements --accept-package-agreements --override "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools;includeRecommended"
winget install --id JRSoftware.InnoSetup --exact --silent --accept-source-agreements --accept-package-agreements
Push-Location $Project
try {
  flutter pub get
  if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }
  flutter build windows --release
  if ($LASTEXITCODE -ne 0) { throw 'flutter build windows failed.' }
} finally { Pop-Location }
$Release = Join-Path $Project 'build\windows\x64\runner\Release'
$Exe = Get-ChildItem $Release -Filter '*.exe' | Select-Object -First 1
if ($null -eq $Exe) { throw 'Windows executable was not found.' }
$Iscc = Get-ChildItem ${env:ProgramFiles(x86)},$env:ProgramFiles -Filter ISCC.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($null -eq $Iscc) { throw 'Inno Setup compiler was not found.' }
& $Iscc.FullName "/DMyAppName=$AppName" "/DMyAppExeName=$($Exe.Name)" "/DMyPackageName=$PackageName" "/DMyAppVersion=$AppVersion" (Join-Path $Root 'inno\setup.iss')
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }
POWERSHELL''',
        r'''cat > "$WINDOWS_KIT/inno/setup.iss" <<'INNO'
#ifndef MyAppName
#define MyAppName "Flutter App"
#endif
#ifndef MyAppExeName
#define MyAppExeName "app.exe"
#endif
#ifndef MyPackageName
#define MyPackageName "flutter-app"
#endif
#ifndef MyAppVersion
#define MyAppVersion "1.0.0"
#endif
[Setup]
AppId={{#MyPackageName}-packfoundry}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\{#MyAppName}
OutputDir=..\output
OutputBaseFilename={#MyPackageName}-setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
[Files]
Source: "..\project\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent
INNO''',
        r'cd "$WORK_ROOT" && zip -qr "$EXPORT/${APP_NAME}_windows_build_kit.zip" "$(basename "$WINDOWS_KIT")"',
        r'# On Windows: powershell -ExecutionPolicy Bypass -File .\scripts\build_windows.ps1',
      ];
    }

    if (stepId == 'summary') {
      return const [r'find "$EXPORT" -maxdepth 1 -type f -print'];
    }

    if (stepId == 'cleanup') {
      return const [r'rm -rf "$WORK_ROOT"'];
    }

    return switch (stepId) {
      'project' => [
        'set -euo pipefail',
        'PROJECT=${_shellQuote(project)}',
        'EXPORT=${_shellQuote(output)}',
        'APP_NAME=${_shellQuote(appName)}',
        'PACKAGE_NAME=${_shellQuote(packageName)}',
        'VERSION=${_shellQuote(version)}',
        'DESKTOP_ID=${_shellQuote(desktopId)}',
        'ICON=${_shellQuote(icon)}',
        'MAINTAINER=${_shellQuote(maintainer)}',
        'DESCRIPTION=${_shellQuote(description)}',
        r'WORK_ROOT="$(mktemp -d -t packfoundry-manual-XXXXXX)"',
        r'WORKSPACE="$WORK_ROOT/project"',
        r'test -f "$PROJECT/pubspec.yaml"',
        r'mkdir -p "$EXPORT"',
      ],
      'local-build' => const [
        r'flutter pub get',
        r'flutter build linux --release',
      ],
      'bundle' => const [
        r'BUNDLE="$(find "$WORKSPACE/build/linux" -type d -path "*/release/bundle" | head -n 1)"',
        r'test -n "$BUNDLE"',
        r'EXECUTABLE="$(find "$BUNDLE" -maxdepth 1 -type f -perm /111 ! -name "*.so" | head -n 1)"',
        r'test -n "$EXECUTABLE"',
        r'EXECUTABLE_NAME="$(basename "$EXECUTABLE")"',
      ],
      _ => const [],
    };
  }

  String _normalizeCommand(String command) {
    return command.replaceAll(r'\"', '"');
  }

  String _shellQuote(String value) {
    return "'${value.replaceAll("'", "'\\''")}'";
  }

  String _slugify(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'flutter-app' : slug;
  }

  String _releaseVersion(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '1.0.0';
    }
    if (trimmed.length > 1 &&
        (trimmed.startsWith('v') || trimmed.startsWith('V'))) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  Color _groupColor(int index) {
    const colors = [
      Color(0xFF0F766E),
      Color(0xFF2563EB),
      Color(0xFF7C3AED),
      Color(0xFFCA8A04),
      Color(0xFFDC2626),
      Color(0xFF0891B2),
    ];
    return colors[index % colors.length];
  }
}

class _CommandGroupData {
  const _CommandGroupData({
    required this.step,
    required this.commands,
    required this.firstCommandNumber,
    required this.color,
  });

  final BuildRoadmapStep step;
  final List<String> commands;
  final int firstCommandNumber;
  final Color color;
}

class _CommandGroup extends StatelessWidget {
  const _CommandGroup({required this.group});

  final _CommandGroupData group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final stateColor = _stateColor(context, group.step.state);

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: group.step.state == BuildRoadmapStepState.running
              ? stateColor.withValues(alpha: 0.08)
              : colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 5, child: ColoredBox(color: group.color)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _stateIcon(group.step.state),
                            size: 18,
                            color: stateColor,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              l10n.roadmapStepTitle(
                                group.step.id,
                                group.step.title,
                              ),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.roadmapStepDescription(
                          group.step.id,
                          group.step.description,
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (
                        var index = 0;
                        index < group.commands.length;
                        index++
                      )
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index == group.commands.length - 1 ? 0 : 7,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 34,
                                child: Text(
                                  '${group.firstCommandNumber + index}.',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SelectableText(
                                  group.commands[index],
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _stateIcon(BuildRoadmapStepState state) {
    return switch (state) {
      BuildRoadmapStepState.pending => Icons.schedule_outlined,
      BuildRoadmapStepState.running => Icons.sync,
      BuildRoadmapStepState.success => Icons.check_circle_outline,
      BuildRoadmapStepState.warning => Icons.error_outline,
      BuildRoadmapStepState.skipped => Icons.skip_next_outlined,
    };
  }

  Color _stateColor(BuildContext context, BuildRoadmapStepState state) {
    return switch (state) {
      BuildRoadmapStepState.pending => Theme.of(
        context,
      ).colorScheme.onSurfaceVariant,
      BuildRoadmapStepState.running => Theme.of(context).colorScheme.primary,
      BuildRoadmapStepState.success => const Color(0xFF16A34A),
      BuildRoadmapStepState.warning => const Color(0xFFDC2626),
      BuildRoadmapStepState.skipped => const Color(0xFFF59E0B),
    };
  }
}

class _BuildStatusChip extends StatelessWidget {
  const _BuildStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BuildRoadmap extends StatefulWidget {
  const _BuildRoadmap({required this.steps});

  final List<BuildRoadmapStep> steps;

  @override
  State<_BuildRoadmap> createState() => _BuildRoadmapState();
}

class _BuildRoadmapState extends State<_BuildRoadmap> {
  String? _expandedStepId;
  String? _lastRunningStepId;

  @override
  void initState() {
    super.initState();
    _syncExpandedStepWithRunningStep();
  }

  @override
  void didUpdateWidget(_BuildRoadmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncExpandedStepWithRunningStep();
    if (_expandedStepId == null) {
      return;
    }
    final stillExists = widget.steps.any((step) => step.id == _expandedStepId);
    if (!stillExists) {
      _expandedStepId = null;
    }
  }

  void _syncExpandedStepWithRunningStep() {
    final runningStepId = _runningStepId();
    if (runningStepId != null && runningStepId != _lastRunningStepId) {
      _expandedStepId = runningStepId;
    }
    _lastRunningStepId = runningStepId;
  }

  String? _runningStepId() {
    for (final step in widget.steps) {
      if (step.state == BuildRoadmapStepState.running) {
        return step.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final expandedWidth = constraints.maxWidth < 520
            ? constraints.maxWidth
            : 520.0;

        return Wrap(
          spacing: 10,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var index = 0; index < widget.steps.length; index++) ...[
              _RoadmapStepCard(
                step: widget.steps[index],
                expanded: widget.steps[index].id == _expandedStepId,
                expandedWidth: expandedWidth,
                onTap: () {
                  setState(() {
                    final stepId = widget.steps[index].id;
                    _expandedStepId = _expandedStepId == stepId ? null : stepId;
                  });
                },
              ),
              if (index != widget.steps.length - 1)
                Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ],
        );
      },
    );
  }
}

class _RoadmapStepCard extends StatelessWidget {
  const _RoadmapStepCard({
    required this.step,
    required this.expanded,
    required this.expandedWidth,
    required this.onTap,
  });

  final BuildRoadmapStep step;
  final bool expanded;
  final double expandedWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(context);
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final running = step.state == BuildRoadmapStepState.running;

    return Semantics(
      button: true,
      label: expanded ? l10n.roadmapCollapseHint : l10n.roadmapExpandHint,
      child: AnimatedContainer(
        width: expanded ? expandedWidth : 235,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: expanded ? 0.15 : 0.10),
                border: Border.all(color: color.withValues(alpha: 0.55)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(expanded ? 14 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: color,
                          child: Text(
                            step.number.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.roadmapStepTitle(step.id, step.title),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Icon(_stepIcon(), color: color, size: 18),
                        const SizedBox(width: 4),
                        Icon(
                          expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.roadmapStepDescription(step.id, step.description),
                    ),
                    if (step.detail != null && step.detail!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.roadmapDetail(step.detail!),
                        maxLines: expanded ? null : 2,
                        overflow: expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (running) ...[
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: step.progress.clamp(0, 100) / 100,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _estimateText(context),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    AnimatedSize(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: expanded
                          ? _ExpandedRoadmapDetails(
                              step: step,
                              running: running,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _estimateText(BuildContext context) {
    final seconds = step.estimatedSeconds;
    if (seconds == null) {
      return context.l10n.roadmapRunning;
    }
    if (seconds < 60) {
      return context.l10n.roadmapUsuallySeconds(seconds);
    }
    return context.l10n.roadmapUsuallyMinutes((seconds / 60).round());
  }

  IconData _stepIcon() {
    return switch (step.state) {
      BuildRoadmapStepState.pending => Icons.radio_button_unchecked,
      BuildRoadmapStepState.running => Icons.sync,
      BuildRoadmapStepState.success => Icons.check_circle_outline,
      BuildRoadmapStepState.warning => Icons.error_outline,
      BuildRoadmapStepState.skipped => Icons.skip_next_outlined,
    };
  }

  Color _stepColor(BuildContext context) {
    return switch (step.state) {
      BuildRoadmapStepState.pending => Theme.of(context).colorScheme.outline,
      BuildRoadmapStepState.running => Theme.of(context).colorScheme.primary,
      BuildRoadmapStepState.success => const Color(0xFF16A34A),
      BuildRoadmapStepState.warning => const Color(0xFFDC2626),
      BuildRoadmapStepState.skipped => const Color(0xFFF59E0B),
    };
  }
}

class _ExpandedRoadmapDetails extends StatelessWidget {
  const _ExpandedRoadmapDetails({required this.step, required this.running});

  final BuildRoadmapStep step;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: 6),
          Text(
            l10n.roadmapDetailsTitle,
            style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            step.id.contains(':')
                ? l10n.visualSubstepExpandedDetail
                : l10n.roadmapStepExpandedDetail(step.id),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RoadmapInfoChip(
                icon: Icons.flag_outlined,
                label: l10n.roadmapStatusLabel(step.state.name),
              ),
              _RoadmapInfoChip(
                icon: Icons.percent,
                label: l10n.roadmapProgressLabel(step.progress),
              ),
              if (running)
                _RoadmapInfoChip(
                  icon: Icons.timer_outlined,
                  label: _estimateText(context),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _estimateText(BuildContext context) {
    final seconds = step.estimatedSeconds;
    if (seconds == null) {
      return context.l10n.roadmapRunning;
    }
    if (seconds < 60) {
      return context.l10n.roadmapUsuallySeconds(seconds);
    }
    return context.l10n.roadmapUsuallyMinutes((seconds / 60).round());
  }
}

class _RoadmapInfoChip extends StatelessWidget {
  const _RoadmapInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final BuildLogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_entryIcon(entry.state), color: _entryColor(context), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(entry.detail),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _entryIcon(BuildLogState state) {
    return switch (state) {
      BuildLogState.idle => Icons.radio_button_unchecked,
      BuildLogState.running => Icons.sync,
      BuildLogState.success => Icons.check_circle_outline,
      BuildLogState.warning => Icons.warning_amber_outlined,
    };
  }

  Color _entryColor(BuildContext context) {
    return switch (entry.state) {
      BuildLogState.idle => Theme.of(context).colorScheme.onSurfaceVariant,
      BuildLogState.running => Theme.of(context).colorScheme.primary,
      BuildLogState.success => const Color(0xFF16A34A),
      BuildLogState.warning => const Color(0xFFF59E0B),
    };
  }
}
