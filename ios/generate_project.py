#!/usr/bin/env python3
"""Regenerate the checked-in Xcode project with Python 3; no dependencies required."""
import hashlib
import json
import plistlib
from pathlib import Path
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parent
objects = {}


def identifier(name):
    return hashlib.sha256(name.encode()).hexdigest()[:24].upper()


def add(stable_key, isa, **fields):
    key = identifier(stable_key)
    objects[key] = {"isa": isa, **fields}
    return key


def source_group(directory, phase_files):
    children = []
    for path in sorted(directory.iterdir()):
        relative = path.relative_to(ROOT).as_posix()
        if path.is_dir():
            children.append(source_group(path, phase_files))
        elif path.suffix == ".swift":
            reference = add(relative, "PBXFileReference", lastKnownFileType="sourcecode.swift", path=path.name, sourceTree="<group>")
            phase_files.append(add(relative + ":build", "PBXBuildFile", fileRef=reference))
            children.append(reference)
        elif path.suffix == ".plist":
            children.append(add(relative, "PBXFileReference", lastKnownFileType="text.plist.xml", path=path.name, sourceTree="<group>"))
    return add(str(directory.relative_to(ROOT)) + ":group", "PBXGroup", children=children, path=directory.name, sourceTree="<group>")


# Keep ATS exceptions out of the Release application.
info = {
    "CFBundleDevelopmentRegion": "$(DEVELOPMENT_LANGUAGE)",
    "CFBundleDisplayName": "Catalogue",
    "CFBundleExecutable": "$(EXECUTABLE_NAME)",
    "CFBundleIdentifier": "$(PRODUCT_BUNDLE_IDENTIFIER)",
    "CFBundleInfoDictionaryVersion": "6.0",
    "CFBundleName": "$(PRODUCT_NAME)",
    "CFBundlePackageType": "$(PRODUCT_BUNDLE_PACKAGE_TYPE)",
    "CFBundleShortVersionString": "1.0",
    "CFBundleVersion": "1",
    "LSRequiresIPhoneOS": True,
    "CatalogueAPIBaseURL": "$(CATALOGUE_API_BASE_URL)",
    "UILaunchScreen": {},
    "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
    "UISupportedInterfaceOrientations~ipad": ["UIInterfaceOrientationPortrait", "UIInterfaceOrientationPortraitUpsideDown", "UIInterfaceOrientationLandscapeLeft", "UIInterfaceOrientationLandscapeRight"],
    "UIApplicationSceneManifest": {
        "UIApplicationSupportsMultipleScenes": False,
        "UISceneConfigurations": {"UIWindowSceneSessionRoleApplication": [{
            "UISceneConfigurationName": "Default Configuration",
            "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
        }]},
    },
}
for configuration in ("Debug", "Release"):
    values = dict(info)
    if configuration == "Debug":
        values["NSLocalNetworkUsageDescription"] = "Connect to your local catalogue server during development."
        values["NSAppTransportSecurity"] = {
            "NSAllowsLocalNetworking": True,
            "NSExceptionDomains": {"localhost": {"NSExceptionAllowsInsecureHTTPLoads": True}},
        }
    (ROOT / "ProductCatalogue" / f"Info-{configuration}.plist").write_bytes(plistlib.dumps(values, sort_keys=False))

app_sources, test_sources = [], []
app_group = source_group(ROOT / "ProductCatalogue", app_sources)
test_group = source_group(ROOT / "ProductCatalogueTests", test_sources)
app_product = add("app:product", "PBXFileReference", explicitFileType="wrapper.application", includeInIndex=0, path="ProductCatalogue.app", sourceTree="BUILT_PRODUCTS_DIR")
test_product = add("test:product", "PBXFileReference", explicitFileType="wrapper.cfbundle", includeInIndex=0, path="ProductCatalogueTests.xctest", sourceTree="BUILT_PRODUCTS_DIR")
products_group = add("products:group", "PBXGroup", children=[app_product, test_product], name="Products", sourceTree="<group>")
main_group = add("main:group", "PBXGroup", children=[app_group, test_group, products_group], sourceTree="<group>")

project_configs, app_configs, test_configs = [], [], []
for configuration in ("Debug", "Release"):
    debug = configuration == "Debug"
    project_configs.append(add("project:" + configuration, "XCBuildConfiguration", name=configuration, buildSettings={
        "SDKROOT": "iphoneos", "IPHONEOS_DEPLOYMENT_TARGET": "16.0", "SWIFT_VERSION": "5.0",
        "CLANG_ENABLE_MODULES": "YES", "CLANG_ENABLE_OBJC_ARC": "YES",
        "SWIFT_OPTIMIZATION_LEVEL": "-Onone" if debug else "-O",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG" if debug else "",
        "ENABLE_TESTABILITY": "YES" if debug else "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf" if debug else "dwarf-with-dsym",
        "ONLY_ACTIVE_ARCH": "YES" if debug else "NO",
    }))
    app_configs.append(add("app:" + configuration, "XCBuildConfiguration", name=configuration, buildSettings={
        "PRODUCT_NAME": "$(TARGET_NAME)", "PRODUCT_BUNDLE_IDENTIFIER": "com.example.ProductCatalogue",
        "TARGETED_DEVICE_FAMILY": "1,2", "CODE_SIGN_STYLE": "Automatic",
        "SUPPORTED_PLATFORMS": "iphoneos iphonesimulator", "SUPPORTS_MACCATALYST": "NO",
        "INFOPLIST_FILE": f"ProductCatalogue/Info-{configuration}.plist",
        "GENERATE_INFOPLIST_FILE": "NO",
        "CATALOGUE_API_BASE_URL": "https://productcatalogbackend-1.onrender.com/api",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    }))
    test_configs.append(add("test:" + configuration, "XCBuildConfiguration", name=configuration, buildSettings={
        "PRODUCT_NAME": "$(TARGET_NAME)", "PRODUCT_BUNDLE_IDENTIFIER": "com.example.ProductCatalogueTests",
        "TARGETED_DEVICE_FAMILY": "1,2", "GENERATE_INFOPLIST_FILE": "YES", "CODE_SIGN_STYLE": "Automatic",
        "TEST_HOST": "$(BUILT_PRODUCTS_DIR)/ProductCatalogue.app/ProductCatalogue",
        "BUNDLE_LOADER": "$(TEST_HOST)",
        "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks", "@loader_path/Frameworks"],
    }))


def configurations(name, values):
    return add(name + ":configs", "XCConfigurationList", buildConfigurations=values, defaultConfigurationIsVisible=0, defaultConfigurationName="Release")


def phases(name, sources):
    return [add(name + ":sources", "PBXSourcesBuildPhase", buildActionMask=2147483647, files=sources, runOnlyForDeploymentPostprocessing=0),
            add(name + ":frameworks", "PBXFrameworksBuildPhase", buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0),
            add(name + ":resources", "PBXResourcesBuildPhase", buildActionMask=2147483647, files=[], runOnlyForDeploymentPostprocessing=0)]

app_target = add("app:target", "PBXNativeTarget", name="ProductCatalogue", productName="ProductCatalogue", productType="com.apple.product-type.application", productReference=app_product, buildConfigurationList=configurations("app", app_configs), buildPhases=phases("app", app_sources), buildRules=[], dependencies=[])
proxy = add("test:proxy", "PBXContainerItemProxy", containerPortal=identifier("project"), proxyType=1, remoteGlobalIDString=app_target, remoteInfo="ProductCatalogue")
dependency = add("test:dependency", "PBXTargetDependency", target=app_target, targetProxy=proxy)
test_target = add("test:target", "PBXNativeTarget", name="ProductCatalogueTests", productName="ProductCatalogueTests", productType="com.apple.product-type.bundle.unit-test", productReference=test_product, buildConfigurationList=configurations("test", test_configs), buildPhases=phases("test", test_sources), buildRules=[], dependencies=[dependency])
project = add("project", "PBXProject", attributes={"LastUpgradeCheck": "1600", "TargetAttributes": {app_target: {"CreatedOnToolsVersion": "16.0"}, test_target: {"CreatedOnToolsVersion": "16.0", "TestTargetID": app_target}}}, buildConfigurationList=configurations("project", project_configs), compatibilityVersion="Xcode 14.0", developmentRegion="en", hasScannedForEncodings=0, knownRegions=["en", "Base"], mainGroup=main_group, productRefGroup=products_group, projectDirPath="", projectRoot="", targets=[app_target, test_target])


def openstep(value, indent=0):
    tab = "\t" * indent
    if isinstance(value, dict):
        return "{\n" + "".join(f"{tab}\t{json.dumps(key)} = {openstep(item, indent + 1)};\n" for key, item in value.items()) + tab + "}"
    if isinstance(value, list):
        return "(\n" + "".join(f"{tab}\t{openstep(item, indent + 1)},\n" for item in value) + tab + ")"
    return str(value) if isinstance(value, int) else json.dumps(value)

project_path = ROOT / "ProductCatalogue.xcodeproj"
project_path.mkdir(exist_ok=True)
(project_path / "project.pbxproj").write_text("// !$*UTF8*$!\n" + openstep({"archiveVersion": 1, "classes": {}, "objectVersion": 56, "objects": objects, "rootObject": project}) + "\n")

scheme = ET.Element("Scheme", LastUpgradeVersion="1600", version="1.3")


def reference(parent, target=app_target, name="ProductCatalogue", product="ProductCatalogue.app"):
    ET.SubElement(parent, "BuildableReference", BuildableIdentifier="primary", BlueprintIdentifier=target, BuildableName=product, BlueprintName=name, ReferencedContainer="container:ProductCatalogue.xcodeproj")

build = ET.SubElement(scheme, "BuildAction", parallelizeBuildables="YES", buildImplicitDependencies="YES")
entry = ET.SubElement(ET.SubElement(build, "BuildActionEntries"), "BuildActionEntry", buildForTesting="YES", buildForRunning="YES", buildForProfiling="YES", buildForArchiving="YES", buildForAnalyzing="YES")
reference(entry)
test = ET.SubElement(scheme, "TestAction", buildConfiguration="Debug", selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB", selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", shouldUseLaunchSchemeArgsEnv="YES", codeCoverageEnabled="YES")
reference(ET.SubElement(test, "MacroExpansion"))
testable = ET.SubElement(ET.SubElement(test, "Testables"), "TestableReference", skipped="NO", parallelizable="NO")
reference(testable, test_target, "ProductCatalogueTests", "ProductCatalogueTests.xctest")
launch = ET.SubElement(scheme, "LaunchAction", buildConfiguration="Debug", selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB", selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB", launchStyle="0", useCustomWorkingDirectory="NO", ignoresPersistentStateOnLaunch="NO", debugServiceExtension="internal", allowLocationSimulation="YES")
reference(ET.SubElement(launch, "BuildableProductRunnable", runnableDebuggingMode="0"))
profile = ET.SubElement(scheme, "ProfileAction", buildConfiguration="Release", shouldUseLaunchSchemeArgsEnv="YES", savedToolIdentifier="", useCustomWorkingDirectory="NO", debugServiceExtension="internal")
reference(ET.SubElement(profile, "BuildableProductRunnable", runnableDebuggingMode="0"))
ET.SubElement(scheme, "AnalyzeAction", buildConfiguration="Debug")
ET.SubElement(scheme, "ArchiveAction", buildConfiguration="Release", revealArchiveInOrganizer="YES")
ET.indent(scheme)
scheme_path = project_path / "xcshareddata" / "xcschemes"
scheme_path.mkdir(parents=True, exist_ok=True)
(scheme_path / "ProductCatalogue.xcscheme").write_bytes(ET.tostring(scheme, encoding="utf-8", xml_declaration=True))
print(f"Generated project: {len(app_sources)} application and {len(test_sources)} test Swift files")
