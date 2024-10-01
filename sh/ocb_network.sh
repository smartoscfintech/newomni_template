#!/bin/bash

read -p "Enter yaml filename: " YAML_FILE
read -p "Enter prefix name: " FILE_PREFIX
read -p "Enter service name: " SERVICE_NAME

SERVICE_NAME_LOWERCASE="$(tr '[:upper:]' '[:lower:]' <<< ${SERVICE_NAME:0:1})${SERVICE_NAME:1}"

#service
interfaceName="${SERVICE_NAME}Interface"
kitName="${SERVICE_NAME}Kit"

mkdir -p "$interfaceName"
mkdir -p "$kitName"


# File YAML input
yaml_file="${YAML_FILE}.yaml"

# Đọc các schema đã được định nghĩa
schema_count=$(yq eval '.components.schemas | length' $yaml_file)

servers=$(yq eval '.servers[0].url' $yaml_file)
echo "services: $servers"

Interface_Func=""
TargetBuilder_Case=""
TargetBuilder_TASK=""
TargetBuilder_method=""
TargetBuilder_path=""
TargetBuilder_Implement=""

paths_count=$(yq eval '.paths | length' $yaml_file)
for ((i=0; i<$paths_count; i++)); do
  # Lấy tên của schema
  path=$(yq eval ".paths | keys | .[$i]" $yaml_file)
  # Tách đường dẫn thành các thành phần và lấy hai thành phần cuối cùng
  components=$(echo "$path" | awk -F'/' '{print $(NF-1), $NF}')
  requestBody=""
  responses=""
  # Chuyển đổi thành camelCase và loại bỏ dấu gạch ngang, uppercase ký tự sau dấu gạch ngang
  camelCase=$(echo "$components" | awk -F' ' '{for(i=1;i<=NF;i++) { $i=tolower(substr($i,1,1)) substr($i,2); gsub(/-./, toupper(substr($i, index($i, "-")+1, 1)), $i); gsub(/-/, "", $i) } print}' OFS='')
  item_ref=$(yq eval ".paths.$path.post.requestBody.content.application/json.schema.\$ref" $yaml_file)
  if [ "$item_ref" == "null" ]; then
    item_ref=$(yq eval ".paths.$path.get.requestBody.content.application/json.schema.\$ref" $yaml_file)
  fi
  if [ ! -z "$item_ref" ]; then
    item_type=$(echo "$item_ref" | sed 's|#\/components\/schemas\/||')
    if [ "$item_type" == "null" ]; then
        requestBody=""
      else
        requestBody="${FILE_PREFIX}${item_type}"    
      fi
  else
    requestBody=""
  fi

  item_ref1=$(yq eval ".paths.$path.post.responses.200.content.application/json.schema.\$ref" $yaml_file)
  if [ "$item_ref1" == "null" ]; then
    item_ref1=$(yq eval ".paths.$path.get.responses.200.content.application/json.schema.\$ref" $yaml_file)
  fi

  if [ ! -z "$item_ref1" ]; then
    item_type=$(echo "$item_ref1" | sed 's|#\/components\/schemas\/||')
    if [ "$item_type" == "null" ]; then
      responses=""
    else
      responses="${FILE_PREFIX}${item_type}"    
    fi
  else
    responses=""
  fi
  echo "requestBody: $requestBody"
  echo "responses: $responses"
  echo "camelCase: $camelCase"
  if [ -n "$requestBody" ] && [ -n "$responses" ]; then
    Interface_Func+="func ${camelCase}(request: ${requestBody}) async throws -> ${responses}\n    "
    TargetBuilder_Case+="case ${camelCase}(request: ${requestBody})\n        "
    TargetBuilder_TASK+="case .${camelCase}(let request):\n          return .requestJSONEncodable(request)\n        "
    TargetBuilder_Implement+="
  public func ${camelCase}(request: ${requestBody}) async throws -> ${responses} {
      let target = Target(
          operation: .${camelCase}(request: request),
          baseURL: baseURL
      )
      let result: ${responses} = try await moyaProvider.performRequest(target: target)
      return result
  }\n        "
  elif [ -z "$requestBody" ] && [ -n "$responses" ]; then
    Interface_Func+="func ${camelCase}() async throws -> ${responses}\n    "
    TargetBuilder_Case+="case ${camelCase}()\n    "
    TargetBuilder_TASK+="case .${camelCase}:\n          return .requestPlain\n        "
    TargetBuilder_Implement+="
  public func ${camelCase}() async throws -> ${responses} {
      let target = Target(
          operation: .${camelCase},
          baseURL: baseURL
      )
      let result: ${responses} = try await moyaProvider.performRequest(target: target)
      return result
  }\n        "
  elif [ -n "$requestBody" ] && [ -z "$responses" ]; then
    Interface_Func+="func ${camelCase}(request: ${requestBody}) async throws\n    "
    TargetBuilder_Case+="case ${camelCase}(request: ${requestBody})\n    "
    TargetBuilder_TASK+="case .${camelCase}(let request):\n              return .requestJSONEncodable(request)\n            "
    TargetBuilder_Implement+="
  public func ${camelCase}(request: ${requestBody}) async throws{
      let target = Target(
          operation: .${camelCase}(request: request),
          baseURL: baseURL
      )
      try await moyaProvider.performRequest(target: target)
  }\n        "
  else
    Interface_Func+="func ${camelCase}() async throws\n    "
    TargetBuilder_Case+="case ${camelCase}()\n    "
    TargetBuilder_TASK+="case .${camelCase}:\n          return .requestPlain\n        "
    TargetBuilder_Implement+="
  public func ${camelCase}() async throws {
      let target = Target(
          operation: .${camelCase},
          baseURL: baseURL
      )
      try await moyaProvider.performRequest(target: target)
  }\n        "
  fi
  TargetBuilder_method+="case .${camelCase}:\n            return .post //FIXME: \n         "
  TargetBuilder_path+="case .${camelCase}:\n            return commonPath + \"${path}\"\n          "
    


done

# Loop qua từng schema
for ((i=0; i<$schema_count; i++)); do
  # Lấy tên của schema
  schema_name=$(yq eval ".components.schemas | keys | .[$i]" $yaml_file)
    echo "schema_name: $schema_name"

  # Lấy kiểu của schema (object hoặc array)
  schema_type=$(yq eval ".components.schemas.$schema_name.type" $yaml_file)
    echo "schema_type: $schema_type"
  if [ "$schema_type" == "object" ]; then
    # Bắt đầu tạo file model Swift
    echo "Generating $schema_name.swift..."
    out_put_file_name="${FILE_PREFIX}${schema_name}" 
    output_file="${interfaceName}/${out_put_file_name}.swift"

    # Khởi tạo nội dung struct
    echo -e "import Foundation\nimport OCBKit\n\npublic struct ${FILE_PREFIX}${schema_name}: Codable {" > $output_file

    # Đọc các properties của object
    field_count=$(yq eval ".components.schemas.$schema_name.properties | length" $yaml_file)

    # Loop qua các field
    for ((j=0; j<$field_count; j++)); do
      # Lấy tên và kiểu dữ liệu của field
      field_name=$(yq eval ".components.schemas.$schema_name.properties | keys | .[$j]" $yaml_file)
      field_type=$(yq eval ".components.schemas.$schema_name.properties.$field_name.type" $yaml_file)

      # Chuyển đổi kiểu dữ liệu YAML sang kiểu Swift
      case $field_type in
        string)
          swift_type="String"
          ;;
        number)
          swift_type="Double"
          ;;
        integer)
          swift_type="Int"
          ;;
        boolean)
          swift_type="Bool"
          ;;
        array)
          # Nếu là mảng, cần xác định kiểu của phần tử trong mảng
          item_ref=$(yq eval ".components.schemas.$schema_name.items.\$ref" $yaml_file)
          if [ ! -z "$item_ref" ]; then
            item_type=$(echo "$item_ref" | sed 's|#\/components\/schemas\/||')
            swift_type="[$item_type]"
          else
            swift_type="[Any]"
          fi
          ;;
        *)
          swift_type="Any"
          ;;
      esac

      # Thêm field vào file Swift
      echo "    public let $field_name: ${swift_type}?" >> $output_file
    done

    # Kết thúc struct
    echo "}" >> $output_file

    echo "$output_file has been generated."
elif [ "$schema_type" == "array" ]; then
    echo "Schema type is array"
    item_ref=$(yq eval ".components.schemas.$schema_name.items.\$ref" $yaml_file)
    if [ ! -z "$item_ref" ]; then
    item_type=$(echo "$item_ref" | sed 's|#\/components\/schemas\/||')
    swift_type="[${FILE_PREFIX}${item_type}]"
    else
    swift_type="[Any]"
    fi
    echo "swift_type: ${swift_type}"
    out_put_file_name="${FILE_PREFIX}${schema_name}" 
    output_file="${interfaceName}/${out_put_file_name}.swift"

    # Khởi tạo nội dung struct
    echo -e "import Foundation\nimport OCBKit\n\npublic struct ${FILE_PREFIX}${schema_name}: Codable {
  public let items: ${swift_type}?
}" > $output_file

fi
done


echo -e "
//FIXME: need move to Package.swift (NetworkServiceKit)
.library(
      name: \"${interfaceName}\",
      targets: [\"${interfaceName}\"]
  ),
  .library(
      name: \"${kitName}\",
      targets: [\"${kitName}\"]
  ),

// MARK: - ${SERVICE_NAME}
private func make${interfaceName}Target() -> Target {
    return .target(
        name: \"${interfaceName}\",
        dependencies: [
            .product(name: \"OCBKit\", package: \"OCBKit\"),
            \"NetworkModels\"
        ]
    )
}
    
private func make${kitName}Target() -> Target {
    return .target(
        name: \"${kitName}\",
        dependencies: [
            \"${interfaceName}\",
            \"SMFLogger\",
            \"SwiftyJSON\",
            \"MoyaExt\",
            .product(name: \"Moya\", package: \"Moya\"),
            .product(name: \"SMFBackbaseKit\", package: \"SMFBackbaseKit\"),
        ]
    )
}

//FIXME: need move to Container.swift

#if canImport(${kitName})
    import ${interfaceName}
    import ${kitName}
#endif

#if canImport(${kitName})
    var ${SERVICE_NAME_LOWERCASE}: ParameterFactory<String, ${interfaceName}> {
        ParameterFactory<String, ${interfaceName}>.init(self) { [weak self] jwtToken in
            let url: URL = {
                let result = EnvironmentValues.ocbApiUrl
#if DEBUG
                if OCBPreferences.shared.useMockServer {
                    return EnvironmentValues.mockServerUrl
                } else {
                    return result
                }
#else
                return result
#endif
            }()
            
            let authPlugin = AccessTokenPlugin { _ in
                let lastedToken = self?.lastedToken
                return lastedToken == nil ? jwtToken : (lastedToken ?? \"\")
            }
            
            let moyaProvider: MoyaProvider<${SERVICE_NAME}.Target> = {
                let fallback = MoyaProvider<${SERVICE_NAME}.Target>(
                    plugins: [authPlugin, OCBCurlLoggingPlugin()]
                )
#if canImport(Backbase)
                
                if OCBPreferences.shared.useMockServer {
                    return fallback
                } else {
                    return .init(
                        session: .init(configuration: Backbase.securitySessionConfiguration()),
                        plugins: [authPlugin, OCBCurlLoggingPlugin()]
                    )
                }
#else
                return fallback
#endif
            }()
            
            return ${SERVICE_NAME}(
                baseURL: url,
                moyaProvider: moyaProvider
            )
        }
    }
#endif

" > "TODO_Service.swift"

echo -e "import Foundation
import OCBKit

public protocol ${interfaceName} {
    ${Interface_Func}
}

" > "${interfaceName}/${interfaceName}.swift"

echo -e "import Foundation
import Moya
import OCBPreferencesKit
import os
import ${interfaceName}
import SMFLogger
import NetworkCrashlytics

public struct ${SERVICE_NAME}TargetBuilder: TargetType, AccessTokenAuthorizable {
    let logger: SMFLogger = {
        let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: ${SERVICE_NAME}TargetBuilder.self)
        )
        return .init(logger: logger)
    }()

    let operation: OperationType

    public var baseURL: URL

    /// The path to be appended to `baseURL` to form the full `URL`.
    public var path: String {
        let commonPath = \"${servers}\"
        switch operation {
          ${TargetBuilder_path}
        }
    }

    public var method: Moya.Method {
        switch operation {
        ${TargetBuilder_method}
        }
    }

    /// The type of HTTP task to be performed.
    public var task: Task {
        switch operation {
        ${TargetBuilder_TASK}
        }
    }

    /// The type of validation to perform on the request. Default is `.none`.
    public var validationType: ValidationType {
        .none
    }

    /// The headers to be used in the request.
    public var headers: [String: String]? {
        ["Accept-Language": OCBPreferences.shared.preferredLanguage]
    }

    public var authorizationType: AuthorizationType? {
        return .bearer
    }
}

//
// MARK: - Model
extension ${SERVICE_NAME}TargetBuilder {
    enum OperationType {
        ${TargetBuilder_Case}
    }
}" > "${kitName}/${SERVICE_NAME}TargetBuilder.swift"


echo -e "import Foundation
import Moya
import MoyaExt
import NetworkModels
import ${interfaceName}
import SwiftyJSON
import OCBKit

public struct ${SERVICE_NAME} {
    public typealias Target = ${SERVICE_NAME}TargetBuilder
    public var moyaProvider: MoyaProvider<Target>
    private let baseURL: URL

    public init(
        baseURL: URL,
        moyaProvider: MoyaProvider<Target>
    ) {
        self.baseURL = baseURL
        self.moyaProvider = moyaProvider
    }
}

extension ${SERVICE_NAME}: ${interfaceName} {
    ${TargetBuilder_Implement}
}" > "${kitName}/${SERVICE_NAME}.swift"
