# ModelDetails System
[Source](/github/ai/genai_all/genai_core/lib/vnext_genai/nodes/model/details/details.ex)

Comprehensive model metadata structure. Provides detailed information about AI model capabilities and characteristics.

## Purpose
Creates a standardized system for storing and accessing model metadata across different dimensions. This enables intelligent model selection, usage tracking, and capability assessment.

## Key Components
- Capacity details for throughput and performance
- Costing information for budget planning
- Modality support for multimedia capabilities
- Tool usage capabilities for function calling
- Use case support for task-specific performance
- Benchmarks for standardized performance metrics
- Training and fine-tuning details

## Implementation
- Modular structure with specialized detail modules
- Version tracking for schema evolution
- Standardized type definitions for consistency
- Comprehensive metadata coverage across domains

## Related
- [../model_protocol.ex.elif.md](../model_protocol.ex.elif.md) - Model protocol using details
- [../external_model.ex.elif.md](../external_model.ex.elif.md) - External model with details
- [../../model.ex.elif.md](../../model.ex.elif.md) - Model implementation using details