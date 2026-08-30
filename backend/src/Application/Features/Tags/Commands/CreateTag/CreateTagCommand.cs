using FluentValidation;
using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Tags.Commands.CreateTag;

public record CreateTagCommand(CreateTagRequestDto Request) : IRequest<TagDto>;

public class CreateTagCommandValidator : AbstractValidator<CreateTagCommand>
{
    public CreateTagCommandValidator()
    {
        RuleFor(v => v.Request.Name)
            .NotEmpty().WithMessage("Tag name is required.")
            .MaximumLength(50).WithMessage("Tag name cannot exceed 50 characters.");
    }
}

public class CreateTagCommandHandler : IRequestHandler<CreateTagCommand, TagDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public CreateTagCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<TagDto> Handle(CreateTagCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var name = request.Request.Name.Trim().ToLowerInvariant();

        var existing = await _unitOfWork.Tags.GetByNameAsync(name, userId, cancellationToken);
        if (existing != null)
        {
            return _mapper.Map<TagDto>(existing);
        }

        var tag = new Tag
        {
            Id = Guid.NewGuid(),
            Name = name,
            UserId = userId,
            CreatedDate = DateTime.UtcNow
        };

        await _unitOfWork.Tags.AddAsync(tag, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return _mapper.Map<TagDto>(tag);
    }
}
