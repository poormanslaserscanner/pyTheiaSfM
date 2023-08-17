#pragma once

#include <Eigen/Core>
#include <unordered_map>
#include <vector>

#include "theia/math/rotation.h"

namespace theia {

std::unordered_map<ViewId, Eigen::Vector3d> AlignOrientationsWrapper(
    const std::unordered_map<ViewId, Eigen::Vector3d>& gt_rotations,
    const std::unordered_map<ViewId, Eigen::Vector3d>& rotations);

}  // namespace theia